import datetime
from pfio import pfread, pfwrite
import xarray as xr
import pandas as pd
import os
import argparse
import sys
import glob
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import AxesGrid
from matplotlib import rcParams, animation
import matplotlib
matplotlib.rcParams['animation.embed_limit'] = 2**128

class outputs():
    
    varDict = {'pressure':'press.*',
               'saturation':'satur.*',
               'porosity':'porosity',
               'specific_storage':'specific_storage'}
    nanDict = {'pressure':-3.4028234663852886e+38,
               'saturation':-3.4028234663852886e+38,
               'porosity':1,
               'specific_storage':0,
               'slopex':-999,
               'slopey':-999}
    nx = 64
    ny = 128
    nz = 5
    dzScale = np.array([0.5,0.005,0.003,0.0015,0.0005])
    dx = 1000
    dy = 1000
    dz = 200 * dzScale
    mannings = 0.0000044
    slopex_file = '/sfs_slopex.pfb'
    slopey_file = '/sfs_slopey.pfb'
    
    def __init__(self,outpath,runname,timesteps,
                 varDict=varDict,nanDict=nanDict,
                 nx=nx,ny=ny,nz=nz,dx=dx,dy=dy,dz=dz,
                 slopex_file=slopex_file,
                 slopey_file=slopey_file,
                 mannings=mannings):
        self.outpath = outpath
        self.runname = runname
        self.timesteps = timesteps
        self.varDict = varDict
        self.nanDict = nanDict
        self.nx = nx
        self.ny = ny
        self.nz = nz
        self.dx = dx
        self.dy = dy
        self.dz = dz
        self.mannings = mannings
        self.dataset = self.to_dataset()
        self.import_slopes()
    
    def get_files(self,varKey):
        files = glob.glob(os.path.join(self.outpath, f'{self.runname}.out.{self.varDict[varKey]}.pfb'))
        files.sort()
        return files   
        
    def variable_timestep_data_array(self,varKey,timestep):
        file = self.get_files(varKey)[timestep]
        array = np.flip(pfread(file),axis=1)
        array[array==self.nanDict[varKey]]=np.nan
        data_array = xr.DataArray(array,dims=['z','y','x'])
        return data_array
    
    def variable_data_array(self,varKey):
        dataArrays = []
        for file in self.get_files(varKey):
            array = np.flip(pfread(file),axis=1)
            array[array==self.nanDict[varKey]]=np.nan
            data_array = xr.DataArray(array,dims=['z','y','x'])
            dataArrays.append(data_array)
        return dataArrays
    
    def timestep_dataset(self,timestep):
        data_vars = {}
        for key in list(self.varDict.keys()):
            if len(self.get_files(key)) > 1:
                data_vars[key] = (['z','y','x'],self.variable_timestep_data_array(key,timestep))
            else:
                data_vars[key] = (['z','y','x'],self.variable_timestep_data_array(key,0))
        dataset = xr.Dataset(data_vars=data_vars)
        return dataset
    
    def to_dataset(self):
        datasets = []
        for i in np.arange(self.timesteps):
            datasets.append(self.timestep_dataset(i))
        timeseries = xr.concat(datasets,'t')
        return timeseries
    
    def show_var_timestep(self,var,timestep):
        fig = plt.figure(figsize=[15,7])
        fig.suptitle(f'{var}\nt={timestep}',fontsize=14)
        grid = AxesGrid(fig, 111,
                nrows_ncols=(1, 5),
                axes_pad=0,
                cbar_mode='single',
                cbar_location='right',
                cbar_pad=1)
        vmin = self.dataset[var][timestep].min().data.tolist()
        vmax = self.dataset[var][timestep].max().data.tolist()
        vdiff = (vmax-vmin)/10
        for z in np.unique(self.dataset['z']):
            ax = grid[z]
            ax.set_axis_off()
            ax.set_title(f'z = {z}')
            im = ax.imshow(self.dataset[var][timestep,z],vmin=vmin,vmax=vmax,origin='lower')
        cbar = grid.cbar_axes[0].colorbar(im)
        cbar.set_ticks(np.linspace(vmin, vmax, 7))
        plt.close()
        return fig
        
    def animate_var(self,var,viewLayers=np.arange(nz),interval=100):
        axes = []
        artists = []
        #vmin = self.dataset[var].min().data.tolist()
        #vmax = self.dataset[var].max().data.tolist()
        fig = plt.figure()
        fig.suptitle(var)
        for z in np.arange(len(viewLayers)):
            ax = fig.add_subplot(1,len(viewLayers),z+1)
            ax.set_title(f'z = {z}')
            ax.set_axis_off()
            axes.append(ax)
            ax_artists = []
            for t in np.arange(self.timesteps-1):
                vmin = self.dataset[var][t+1].min().data.tolist()
                vmax = self.dataset[var][t+1].max().data.tolist()
                im = [plt.imshow(self.dataset[var][t+1][z],vmin=vmin,vmax=vmax,origin='lower')]
                ax_artists.append(im)
            artists.append(ax_artists)
        new_artists = []
        for timestep in zip(*artists):
            frame = []
            for layer in timestep:
                frame.extend(layer)
            new_artists.append(frame)
        fig.subplots_adjust(right=.83)
        cbar_ax = fig.add_axes([0.85, 0.25, 0.015, 0.5])
        fig.colorbar(new_artists[0][0], cax=cbar_ax)
        plt.rcParams['animation.html'] = 'jshtml'
        anim = animation.ArtistAnimation(fig, new_artists, interval=interval)
        plt.close()
        return anim
    
    def compute_subsurface_storage(self):
        sss = []
        for z in np.arange(self.nz):
            sss.append((self.dataset['saturation'][:,z,:,:] * \
                        self.dataset['porosity'][:,z,:,:] * \
                        self.dx * self.dy * self.dz[z]) + \
                        (self.dataset['pressure'][:,z,:,:] * \
                        self.dataset['specific_storage'][:,z,:,:] * \
                        self.dataset['saturation'][:,z,:,:] * \
                        self.dx * self.dy * self.dz[z]))
        sss = xr.concat(sss,'z').transpose('t','z','y','x')
        self.dataset['subsurface_storage'] = sss
    
    def compute_surface_storage(self):
        top = self.dataset['pressure']['z'].max().data.tolist()
        ss = self.dataset['pressure'][:,top,:,:] * self.dx * self.dy
        self.dataset['surface_storage'] = ss
    
    def compute_gw_storage(self):
        saturated = self.dataset['saturation'].copy(deep=True).data
        saturated[saturated<1]=0
        saturated = xr.DataArray(saturated,dims=['t','z','y','x'])
        self.compute_subsurface_storage()
        gws = saturated * self.dataset['subsurface_storage']
        self.dataset['groundwater_storage'] = gws
    
    def import_slopes(self):
        slopex_path = self.outpath + self.slopex_file
        slopex = np.flip(pfread(slopex_path),axis=1)[0]
        slopex[slopex==self.nanDict['slopex']]=np.nan
        slopex = xr.DataArray(slopex,dims=['y','x'])
        self.dataset['slopex'] = slopex
        slopey_path = self.outpath + self.slopey_file
        slopey = np.flip(pfread(slopey_path),axis=1)[0]
        slopey[slopey==self.nanDict['slopey']]=np.nan
        slopey = xr.DataArray(slopey,dims=['y','x'])
        self.dataset['slopey'] = slopey
    
    def compute_surface_runoff(self):
        top = self.dataset['pressure']['z'].max().data.tolist()
        self.import_slopes()
        y,x = np.where(~np.isnan(self.dataset['slopey']))
        def calc(t,y,x,s): # define outside
            runoff[y,x]=\
            np.sqrt(np.abs(self.dataset[s][y,x]))/\
            self.mannings*\
            self.dataset['pressure'][t,top,y,x]**(5.0/3.0)*\
            self.dy
        surface_runoff = []
        for t in np.arange(self.timesteps):
            runoff = np.empty([self.ny,self.nx])
            runoff[:] = 0
            for i in np.arange(len(y)):
                if np.isnan(self.dataset['slopey'][y[i]-1,x[i]]):
                    if self.dataset['slopey'][y[i],x[i]]>0:
                        if self.dataset['pressure'][t,top,y[i],x[i]]>0:
                            calc(t,y[i],x[i],'slopey')     
                elif np.isnan(self.dataset['slopey'][y[i]+1,x[i]]):
                    if self.dataset['slopey'][y[i],x[i]]<0:
                        if self.dataset['pressure'][t,top,y[i],x[i]]>0:
                            calc(t,y[i],x[i],'slopey')     
                if np.isnan(self.dataset['slopex'][y[i],x[i]-1]):
                    if self.dataset['slopex'][y[i],x[i]]>0:
                        if self.dataset['pressure'][t,top,y[i],x[i]]>0:
                            calc(t,y[i],x[i],'slopex')      
                elif np.isnan(self.dataset['slopex'][y[i],x[i]+1]):
                    if self.dataset['slopex'][y[i],x[i]]<0:
                        if self.dataset['pressure'][t,top,y[i],x[i]]>0:
                            calc(t,y[i],x[i],'slopex')
            runoff = xr.DataArray(runoff,dims=['y','x'])
            surface_runoff.append(runoff)
        surface_runoff = xr.concat(surface_runoff,'t')
        self.dataset['surface_runoff'] = surface_runoff
            