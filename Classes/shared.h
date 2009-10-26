/* Shared.h - scrobble shared data
 * Copyright (C) 2007 Tony Hoyle
 *
 * This file is part of Scrobble.
 *
 * Scrobble is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3
 * as published by the Free Software Foundation.
 *
 * Scrobble is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

typedef  enum {
	SCROBBLER_OFFLINE=0 ,
	SCROBBLER_AUTHENTICATING,
	SCROBBLER_READY,
	SCROBBLER_SCROBBLING,
	SCROBBLER_NOWPLAYING
} scrobbleState_t;