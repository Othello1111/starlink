/*
*+
*  Name:
*     MATH_RND

*  Purpose:
*     Calculate a pseudo-random number in the range [0,1)

*  Language:
*     Starlink ANSI C

*  Invocation:
*     REALVAR = MATH_RND()

*  Description:
*     Return random real in range [0,1) using the current set of state
*     information in the math random number package.
*
*     Note that most of the code in this file is derived from code written
*     by University of California, Berkeley, and their copyright/disclaimer
*     appears at the end of this header.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     None.

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     The MATH random number routines work on random number state information.
*     There is a current set of state info defined globally which defines 32
*     bytes of state data which provides a very good generator compared to
*     normal linear congruential generators. The MATH_IRND and MATH_RND
*     routines have no arguments and simply get the next number in the sequence
*     from the current state info. MATH_SETRND( seed ) lets the seed of the
*     current generator be set. MATH_INITRNDSTATE( seed, statedata, nbytes )
*     sets the current state data area to <statedata> which must be at least
*     <nbytes> long. The generator is initialised with <seed>. This routine
*     returns the address of the old state data as an integer value. The
*     MATH_SETRNDSTATE( statedata ) enables state info to be swapped. The old
*     state data address is returned by this function.
*
*     An improved random number generation package. In addition to the standard
*     rand()/srand() like interface, this package also has a special state info
*     interface. The MATH_INITRNDSTATE() routine is called with a seed, an
*     array of bytes, and a count of how many bytes are being passed in; this
*     array is then initialized to contain information for random number
*     generation with that much state information. Good sizes for the amount of
*     state information are 32, 64, 128, and 256 bytes. The state can be
*     switched by calling the MATH_SETRNDSTATE() function with the same array
*     as was initiallized with MATH_INITRNDSTATE(). By default, the package
*     runs with 128 bytes of state information and generates far better random
*     numbers than a linear congruential generator. If the amount of state
*     information is less than 32 bytes, a simple linear congruential R.N.G.
*     is used. Internally, the state information is treated as an array of
*     longs; the zeroeth element of the array is the type of R.N.G. being used
*     (small integer); the remainder of the array is the state information for
*     the R.N.G.  Thus, 32 bytes of state information will give 7 longs worth
*     of state information, which will allow a degree seven polynomial.
*     (Note: The zeroeth word of state information also has some other
*     information stored in it; see MATH_SETRNDSTATE for details). The random
*     number generation technique is a linear feedback shift register approach,
*     employing trinomials (since there are fewer terms to sum up that way).
*     In this approach, the least significant bit of all the numbers in the
*     state table will act as a linear feedback shift register, and will have
*     period 2^deg - 1 (where deg is the degree of the polynomial being used,
*     assuming that the polynomial is irreducible and primitive). The higher
*     order bits will have longer periods, since their values are also
*     influenced by pseudo-random carries out of the lower bits. The total
*     period of the generator is approximately deg*(2**deg - 1); thus doubling
*     the amount of state information has a vast influence on the period of
*     the generator.  Note: The deg*(2**deg - 1) is an approximation only good
*     for large deg, when the period of the shift register is the dominant
*     factor. With deg equal to seven, the period is actually much longer than
*     the 7*(2**7 - 1) predicted by this formula.

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     MATH Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/math.html

*  Keywords:
*     package:math, usage:public, random numbers

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     Roland McGrath (GNU)
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*      7 Jun 1988:
*        Version taken from Berkeley source archive.
*     13 Jul 1993 (DJA):
*        Added this header to the Berkeley code below. Changed names
*        of routines to match ASTERIX conventions.
*     18 Nov 1993 (DJA):
*        Long's changed to int's due to longs being 64-bit on
*        Alpha and probably other 64-bit machines.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

/*
 * Copyright (c) 1983 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * This is derived from the Berkeley source:
 *	@(#)random.c	5.5 (Berkeley) 7/6/88
 * It was reworked for the GNU C Library by Roland McGrath.
 */



/*
 *  Include files
 */
#include "sae_par.h"
#include "f77.h"
#include <errno.h>

#define	ULONG_MAX  ((unsigned int)(~0L))     /* 0xFFFFFFFF for 32-bits */
#define	LONG_MAX   ((int)(ULONG_MAX >> 1))   /* 0x7FFFFFFF for 32-bits*/

#ifdef __STDC__
#  define PTR void *
#  define NULL (void *) 0
#else
#  define PTR char *
#  define NULL 0
#endif

F77_INTEGER_FUNCTION(math_irnd)();



/*
 *  Body of code
 */
F77_REAL_FUNCTION(math_rnd)()
  {
  return ((float) F77_CALL(math_irnd)())/((float) LONG_MAX);
  }




/*
*+  MATH_RND - Package of random number routines
*
*    Description :
*
*     Provides a package of random number generators. The routines are,
*
*      MATH_IRND         - Return random integer between 0 and LONG_MAX.
*      MATH_RND          - Return random real in range [0,1)
*      MATH_INITRNDSTATE - Initialise new state information
*      MATH_SETRND       - Set seed of a generator
*      MATH_SETRNDSTATE  - Swap generator state information
*
*    Invokation :
*
*      INTEGER   MATH_IRND()
*      REAL      MATH_RND()
*      [INTEGER] MATH_INITRNDSTATE( INTEGER SEED, INTEGER STATEDATA,
*                                   INTEGER NBYTES )
*      [INTEGER] MATH_SETRNDSTATE( INTEGER SEED )
*                MATH_SETRND( SEED )
*




/* For each of the currently supported random number generators, we have a
   break value on the amount of state information (you need at least thi
   bytes of state info to support this random number generator), a degree for
   the polynomial (actually a trinomial) that the R.N.G. is based on, and
   separation between the two lower order coefficients of the trinomial.  */

/* Linear congruential.  */
#define	TYPE_0		0
#define	BREAK_0		8
#define	DEG_0		0
#define	SEP_0		0

/* x**7 + x**3 + 1.  */
#define	TYPE_1		1
#define	BREAK_1		32
#define	DEG_1		7
#define	SEP_1		3

/* x**15 + x + 1.  */
#define	TYPE_2		2
#define	BREAK_2		64
#define	DEG_2		15
#define	SEP_2		1

/* x**31 + x**3 + 1.  */
#define	TYPE_3		3
#define	BREAK_3		128
#define	DEG_3		31
#define	SEP_3		3

/* x**63 + x + 1.  */
#define	TYPE_4		4
#define	BREAK_4		256
#define	DEG_4		63
#define	SEP_4		1


/* Array versions of the above information to make code run faster.
   Relies on fact that TYPE_i == i.  */

#define	MAX_TYPES	5	/* Max number of types above.  */

static int degrees[MAX_TYPES] = { DEG_0, DEG_1, DEG_2, DEG_3, DEG_4 };
static int seps[MAX_TYPES] = { SEP_0, SEP_1, SEP_2, SEP_3, SEP_4 };



/* Initially, everything is set up as if from:
	initstate(1, randtbl, 128);
   Note that this initialization takes advantage of the fact that srandom
   advances the front and rear pointers 10*rand_deg times, and hence the
   rear pointer which starts at 0 will also end up at zero; thus the zeroeth
   element of the state information, which contains info about the current
   position of the rear pointer is just
	(MAX_TYPES * (rptr - state)) + TYPE_3 == TYPE_3.  */

static int randtbl[DEG_3 + 1] =
  { TYPE_3,
      0x9a319039, 0x32d9c024, 0x9b663182, 0x5da1f342,
      0xde3b81e0, 0xdf0a6fb5, 0xf103bc02, 0x48f340fb,
      0x7449e56b, 0xbeb1dbb0, 0xab5c5918, 0x946554fd,
      0x8c2e680f, 0xeb3d799f, 0xb11ee0b7, 0x2d436b86,
      0xda672e2a, 0x1588ca88, 0xe369735d, 0x904f35f7,
      0xd7158fd6, 0x6fa6f051, 0x616e6b96, 0xac94efdc,
      0x36413f93, 0xc622c298, 0xf5a42ab8, 0x8a88d77b,
      0xf5ad9d0e, 0x8999220b, 0x27fb47b9
    };

/* FPTR and RPTR are two pointers into the state info, a front and a rear
   pointer.  These two pointers are always rand_sep places aparts, as they
   cycle through the state information.  (Yes, this does mean we could get
   away with just one pointer, but the code for random is more efficient
   this way).  The pointers are left positioned as they would be from the call:
	initstate(1, randtbl, 128);
   (The position of the rear pointer, rptr, is really 0 (as explained above
   in the initialization of randtbl) because the state table pointer is set
   to point to randtbl[1] (as explained below).)  */

static int *fptr = &randtbl[SEP_3 + 1];
static int *rptr = &randtbl[1];



/* The following things are the pointer to the state information table,
   the type of the current generator, the degree of the current polynomial
   being used, and the separation between the two pointers.
   Note that for efficiency of random, we remember the first location of
   the state information, not the zeroeth.  Hence it is valid to access
   state[-1], which is used to store the type of the R.N.G.
   Also, we remember the last location, since this is more efficient than
   indexing every time to find the address of the last element to see if
   the front and rear pointers have wrapped.  */

static int *state = &randtbl[1];

static int rand_type = TYPE_3;
static int rand_deg = DEG_3;
static int rand_sep = SEP_3;

static int *end_ptr = &randtbl[sizeof(randtbl) / sizeof(randtbl[0])];

/* Initialize the random number generator based on the given seed.  If the
   type is the trivial no-state-information type, just remember the seed.
   Otherwise, initializes state[] based on the given "seed" via a linear
   congruential generator.  Then, the pointers are set to known locations
   that are exactly rand_sep places apart.  Lastly, it cycles the state
   information a given number of times to get rid of any initial dependencies
   introduced by the L.C.R.N.G.  Note that the initialization of randtbl[]
   for default usage relies on values produced by this routine.  */

F77_SUBROUTINE(math_setrnd)( INTEGER(rseed) )
  {
  GENPTR_INTEGER(rseed)

  unsigned int x;

  x = *rseed;
  state[0] = x;
  if (rand_type != TYPE_0)
    {
      register int i;
      for (i = 1; i < rand_deg; ++i)
	state[i] = (1103515145 * state[i - 1]) + 12345;
      fptr = &state[rand_sep];
      rptr = &state[0];
      for (i = 0; i < 10 * rand_deg; ++i)
        (void) F77_CALL(math_irnd)();
    }
  }


/* Initialize the state information in the given array of N bytes for
   future random number generation.  Based on the number of bytes we
   are given, and the break values for the different R.N.G.'s, we choose
   the best (largest) one we can and set things up for it.  MATH_SETRND is
   then called to initialize the state information.  Note that on return from
   MATH_SETRND, we set state[-1] to be the type multiplexed with the current
   value of the rear pointer; this is so successive calls to initstate won't
   lose this information and will be able to restart with math_setrndstate.
   Note: The first thing we do is save the current state, if any, just like
   math_setrndstate so that it doesn't matter when initstate is called.
   Returns a pointer to the old state.  */


PTR F77_EXTERNAL_NAME(math_initrndstate)( INTEGER(pseed),
                                          POINTER(arg_state),
                                          INTEGER(state_size) )
  {
  unsigned int seed;
  unsigned n;

  PTR ostate = (PTR) &state[-1];

  seed = *pseed;
  n = *state_size;

  if (rand_type == TYPE_0)
    state[-1] = rand_type;
  else
    state[-1] = (MAX_TYPES * (rptr - state)) + rand_type;
  if (n < BREAK_1)
    {
      if (n < BREAK_0)
	{
	  errno = EINVAL;
	  return NULL;
	}
      rand_type = TYPE_0;
      rand_deg = DEG_0;
      rand_sep = SEP_0;
    }
  else if (n < BREAK_2)
    {
      rand_type = TYPE_1;
      rand_deg = DEG_1;
      rand_sep = SEP_1;
    }
  else if (n < BREAK_3)
    {
      rand_type = TYPE_2;
      rand_deg = DEG_2;
      rand_sep = SEP_2;
    }
  else if (n < BREAK_4)
    {
      rand_type = TYPE_3;
      rand_deg = DEG_3;
      rand_sep = SEP_3;
    }
  else
    {
      rand_type = TYPE_4;
      rand_deg = DEG_4;
      rand_sep = SEP_4;
    }

  state = &((int *) arg_state)[1];	/* First location.  */
  /* Must set END_PTR before srandom.  */
  end_ptr = &state[rand_deg];
  F77_CALL(math_setrnd)( (F77_INTEGER_TYPE *) &seed );
  if (rand_type == TYPE_0)
    state[-1] = rand_type;
  else
    state[-1] = (MAX_TYPES * (rptr - state)) + rand_type;

  return ostate;
  }


/* Restore the state from the given state array.
   Note: It is important that we also remember the locations of the pointers
   in the current state information, and restore the locations of the pointers
   from the old state information.  This is done by multiplexing the pointer
   location into the zeroeth word of the state information. Note that due
   to the order in which things are done, it is OK to call math_setrndstate
   with the same state as the current state
   Returns a pointer to the old state information.  */

PTR F77_EXTERNAL_NAME(math_setrndstate)( PTR arg_state )
  {
  register int *new_state = (int *) arg_state;
  register int type = new_state[0] % MAX_TYPES;
  register int rear = new_state[0] / MAX_TYPES;
  PTR ostate = (PTR) &state[-1];

  if (rand_type == TYPE_0)
    state[-1] = rand_type;
  else
    state[-1] = (MAX_TYPES * (rptr - state)) + rand_type;

  switch (type)
    {
    case TYPE_0:
    case TYPE_1:
    case TYPE_2:
    case TYPE_3:
    case TYPE_4:
      rand_type = type;
      rand_deg = degrees[type];
      rand_sep = seps[type];
      break;
    default:
      /* State info munged.  */
      errno = EINVAL;
      return NULL;
    }

  state = &new_state[1];
  if (rand_type != TYPE_0)
    {
      rptr = &state[rear];
      fptr = &state[(rear + rand_sep) % rand_deg];
    }
  /* Set end_ptr too.  */
  end_ptr = &state[rand_deg];

  return ostate;
  }


/* If we are using the trivial TYPE_0 R.N.G., just do the old linear
   congruential bit.  Otherwise, we do our fancy trinomial stuff, which is the
   same in all the other cases due to all the global variables that have been
   set up.  The basic operation is to add the number at the rear pointer into
   the one at the front pointer.  Then both pointers are advanced to the next
   location cyclically in the table.  The value returned is the sum generated,
   reduced to 31 bits by throwing away the "least random" low bit.
   Note: The code takes advantage of the fact that both the front and
   rear pointers can't wrap on the same call by not testing the rear
   pointer if the front one has wrapped.  Returns a 31-bit random number.  */

F77_INTEGER_FUNCTION(math_irnd)()
  {
  if (rand_type == TYPE_0)
    {
      state[0] = ((state[0] * 1103515245) + 12345) & LONG_MAX;
      return state[0];
    }
  else
    {
      int i;
      *fptr += *rptr;
      /* Chucking least random bit.  */
      i = (*fptr >> 1) & LONG_MAX;
      ++fptr;
      if (fptr >= end_ptr)
	{
	  fptr = state;
	  ++rptr;
	}
      else
	{
	  ++rptr;
	  if (rptr >= end_ptr)
	    rptr = state;
	}
      return i;
    }
  }
