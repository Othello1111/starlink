/*
*+
*  Name:
*     smf_calcmodel_noi

*  Purpose:
*     Calculate the NOIse model for the bolometers

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_calcmodel_noi( smfWorkForce *wf, smfDIMMData *dat, int
*			 chunk, AstKeyMap *keymap, smfArray
*			 **allmodel, int flags, int *status)

*  Arguments:
*     wf = smfWorkForce * (Given)
*        Pointer to a pool of worker threads
*     dat = smfDIMMData * (Given)
*        Struct of pointers to information required by model calculation
*     chunk = int (Given)
*        Index of time chunk in allmodel to be calculated
*     keymap = AstKeyMap * (Given)
*        Parameters that control the iterative map-maker
*     allmodel = smfArray ** (Returned)
*        Array of smfArrays (each time chunk) to hold result of model calc
*     flags = int (Given )
*        Control flags: estimate VARIANCE only if SMF__DIMM_FIRSTITER set
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Calculate the noise distribution for each detector. Currently this
*     will just assume stationary, independent noise in each detector and
*     measure the sample variance over a short interval. In addition,
*     there is an

*  Notes:

*  Authors:
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2007-03-02 (EC):
*        Initial Version
*     2007-03-05 (EC)
*        Modified bit flags
*     2007-06-13 (EC)
*        Fixed res_data pointer assignment bug
*     2007-07-10 (EC)
*        Use smfArray instead of smfData
*     2008-03-04 (EC)
*        Modified interface to use smfDIMMData
*     2008-04-03 (EC)
*        Use QUALITY
*     2008-04-14 (EC)
*        Added optional despiking config (NOISPIKETHRESH/NOISPIKEITER)
*     2008-04-17 (EC)
*        -fixed nbolo/ntslice calculation
*        -store variance instead of standard deviation
*        -use smf_quick_noise instead of smf_simple_stats on whole array;
*         added config parameters (NOISAMP/NOICHUNK)
*     2008-04-18 (EC)
*        -Only calculate the white noise level once (first iteration)
*        -Add chisquared calculation
*     2008-05-02 (EC)
*        - Use different levels of verbosity in messages
*     2009-04-17 (EC)
*        - switch to subkeymap notation in config file
*     2009-07-21 (EC)
*        - Remove NOISAMP/NOICHUNK related parameters since they aren't used
*     2009-07-31 (EC)
*        - handle 2d variance arrays

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
*     Copyright (C) 2005-2009 University of British Columbia.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Starlink includes */
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

#define FUNC_NAME "smf_calcmodel_noi"


void smf_calcmodel_noi( smfWorkForce *wf, smfDIMMData *dat, int chunk,
                        AstKeyMap *keymap, smfArray **allmodel, int flags,
                        int *status) {

  /* Local Variables */
  size_t aiter;                 /* Actual iterations of sigma clipper */
  size_t bstride;               /* bolometer stride */
  dim_t i;                      /* Loop counter */
  dim_t id;                     /* Loop counter */
  dim_t idx=0;                  /* Index within subgroup */
  dim_t im;                     /* Loop counter */
  dim_t j;                      /* Loop counter */
  AstKeyMap *kmap=NULL;         /* Local keymap */
  unsigned char mask;           /* Bitmask for quality */
  unsigned char mask_spike;     /* Bitmask for quality */
  size_t mbstride;              /* model bolometer stride */
  dim_t mntslice;               /* Number of model time slices */
  size_t mtstride;              /* model time slice stride */
  smfArray *model=NULL;         /* Pointer to model at chunk */
  double *model_data=NULL;      /* Pointer to DATA component of model */
  dim_t nbolo;                  /* Number of bolometers */
  size_t nchisq;                /* Number of data points in chisq calc */
  dim_t ndata;                  /* Total number of data points */
  size_t nflag;                 /* Number of new flags */
  dim_t ntslice;                /* Number of time slices */
  smfArray *qua=NULL;           /* Pointer to RES at chunk */
  unsigned char *qua_data=NULL; /* Pointer to RES at chunk */
  smfArray *res=NULL;           /* Pointer to RES at chunk */
  double *res_data=NULL;        /* Pointer to DATA component of res */
  size_t spikeiter=0;           /* Number of iterations for spike detection */
  int spikeiter_s;              /* signed version of spikeiter */
  double spikethresh=0;         /* Threshold for spike detection */
  size_t tstride;               /* time slice stride */
  double *var=NULL;             /* Sample variance */

  /* Main routine */
  if (*status != SAI__OK) return;

  /* Obtain pointer to sub-keymap containing NOI parameters */
  if( !astMapGet0A( keymap, "NOI", &kmap ) ) {
    kmap = NULL;
  }

  /* Obtain pointers to relevant smfArrays for this chunk */
  res = dat->res[chunk];
  qua = dat->qua[chunk];
  model = allmodel[chunk];

  /* Assert bolo-ordered data */
  for( idx=0; idx<res->ndat; idx++ ) if (*status == SAI__OK ) {
    smf_dataOrder( res->sdata[idx], 0, status );
    smf_dataOrder( qua->sdata[idx], 0, status );
  }

  /* Obtain parameters for NOI */
  if( kmap ) {

    /* Despiker */
    if( !astMapGet0D( kmap, "SPIKETHRESH", &spikethresh ) ) {
      spikethresh = 0;
    }

    if( !astMapGet0I( kmap, "SPIKEITER", &spikeiter_s ) ) {
      spikeiter = 0;
    } else {
      if( spikeiter_s < 0 ) {
        *status = SAI__ERROR;
        errRep("", FUNC_NAME ": NOI.SPIKEITER cannot be < 0.", status );
      } else {
        spikeiter = (size_t) spikeiter_s;
      }
    }
  }

  /* Which QUALITY bits should be considered for ignoring data */
  mask = ~(SMF__Q_JUMP|SMF__Q_STAT);

  /* Which QUALITY bits should be considered for re-flagging spikes */
  mask_spike = ~(SMF__Q_JUMP|SMF__Q_SPIKE|SMF__Q_STAT);

  /* Initialize chisquared */
  dat->chisquared[chunk] = 0;
  nchisq = 0;

  /* Loop over index in subgrp (subarray) */
  for( idx=0; idx<res->ndat; idx++ ) {

    /* Get pointers to DATA components */
    res_data = (res->sdata[idx]->pntr)[0];
    model_data = (model->sdata[idx]->pntr)[0];
    qua_data = (qua->sdata[idx]->pntr)[0];

    if( (res_data == NULL) || (model_data == NULL) || (qua_data == NULL) ) {
      *status = SAI__ERROR;
      errRep( "", FUNC_NAME ": Null data in inputs", status);
    } else {

      /* Get the raw data dimensions */
      smf_get_dims( res->sdata[idx], NULL, NULL, &nbolo, &ntslice, &ndata,
                    &bstride, &tstride, status );

      /* NOI model dimensions */
      smf_get_dims( model->sdata[idx], NULL, NULL, NULL, &mntslice, NULL,
                    &mbstride, &mtstride, status );

      /* Only estimate the white noise level once at the beginning - the
	 reason for this is to make measurements of the convergence
	 easier. */

      var = smf_malloc( nbolo, sizeof(*var), 0, status );

      if( flags & SMF__DIMM_FIRSTITER ) {
        /* Measure the noise from power spectra */
        smf_bolonoise( wf, res->sdata[idx], qua_data, 0, 0.5, SMF__F_WHITELO,
                       SMF__F_WHITEHI, 0, var, NULL, 0, status );

	for( i=0; i<nbolo; i++ ) if( !(qua_data[i*ntslice]&SMF__Q_BADB) ) {
            /* Loop over time and store the variance for each sample */
            for( j=0; j<mntslice; j++ ) {
              model_data[i*mbstride+(j%mntslice)*mtstride] = var[i];
            }
          }
      } else {
        for( i=0; i<nbolo; i++ ) {
          var[i] = model_data[i*mbstride];
        }
      }

      /* Flag spikes in the residual */
      if( spikethresh ) {
	/* Now re-flag */
	smf_flag_spikes( res->sdata[idx], var, qua_data, mask_spike,
			 spikethresh, spikeiter,
			 100, &aiter, &nflag, status );

	msgSeti("THRESH",spikethresh);
	msgSeti("NFLAG",nflag);
	msgSeti("AITER",aiter);
	msgOutif(MSG__VERB," ",
                 "   flagged ^NFLAG new ^THRESH-sig spikes in ^AITER "
                 "iterations", status);
      }

      /* Now calculate contribution to chi^2 */
      if( *status == SAI__OK ) {

        for( i=0; i<nbolo; i++ ) if( !(qua_data[i*bstride]&SMF__Q_BADB) ) {
          for( j=0; j<ntslice; j++ ) {
            id = i*bstride+j*tstride;              /* index in data array */
            im = i*mbstride+(j%mntslice)*mtstride; /* index in NOI array */
            if(model_data[im]>0 && !(qua_data[id]&mask) ) {
              dat->chisquared[chunk] += res_data[id]*res_data[id] /
                model_data[im];
              nchisq++;
            }
          }
        }
      }
    }
  }

  /* Normalize chisquared for this chunk */
  if( (*status == SAI__OK) && (nchisq >0) ) {
    dat->chisquared[chunk] /= (double) nchisq;
  }

  /* Clean Up */
  if( var ) var = smf_free(var, status);

  if( kmap ) kmap = astAnnul( kmap );
}
