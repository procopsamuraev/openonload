/*
** Copyright 2005-2019  Solarflare Communications Inc.
**                      7505 Irvine Center Drive, Irvine, CA 92618, USA
** Copyright 2002-2005  Level 5 Networks Inc.
**
** This program is free software; you can redistribute it and/or modify it
** under the terms of version 2 of the GNU General Public License as
** published by the Free Software Foundation.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
*/

/**************************************************************************\
*//*! \file
** <L5_PRIVATE L5_SOURCE>
** \author  
**  \brief  
**   \date  
**    \cop  (c) Level 5 Networks Limited.
** </L5_PRIVATE>
*//*
\**************************************************************************/

/*! \cidoxg_lib_ciapp */

#include <ci/app.h>


int  ci_app_put_record(int fileno, const void* buf, int bytes)
{
  ci_uint32 rlen;

  ci_assert(buf);
  ci_assert(bytes >= 0);

  rlen = CI_BSWAP_LE32(bytes);
  if( ci_write_exact(fileno, &rlen, 4)   != 4 ||
      ci_write_exact(fileno, buf, bytes) != bytes )
    return -errno;

  return 0;
}

/*! \cidoxg_end */
