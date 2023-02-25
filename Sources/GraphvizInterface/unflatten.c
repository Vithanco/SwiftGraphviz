/* $Id$ $Revision$ */
/* vim:set shiftwidth=4 ts=8: */

/*************************************************************************
 * Copyright (c) 2011 AT&T Intellectual Property 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: See CVS logs. Details at http://www.graphviz.org/
 *************************************************************************/

#include "unflatten.h" //

/*
 * Written by Stephen North
 * Updated by Emden Gansner
 * Adopted for Vithanco by Klaus Kneupner (added unflatten func, added unflatten.h)
 */
#include "config.h"

#include    <stdio.h>
#include    <stdlib.h>
#include    <string.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
//#include    <cgraph.h>

#include <getopt.h>

static int Do_fans = 0;
static int MaxMinlen = 0;
static int ChainLimit = 0;
static int ChainSize = 0;
static Agnode_t *ChainNode;

static int myindegree(Agnode_t *n)
{
	return agdegree(n->root, n, TRUE, FALSE);
}

/* need outdegree without selfarcs */
static int myoutdegree(Agnode_t *n)
{
	Agedge_t 	*e;
	int rv = 0;

	for (e = agfstout(n->root, n); e; e = agnxtout(n->root, e)) {
		if (agtail(e) != aghead(e)) rv++;
	}
	return rv;
}

static int isleaf(Agnode_t * n)
{
    return ((myindegree(n) + myoutdegree(n)) == 1);
}

static int ischainnode(Agnode_t * n)
{
    return ((myindegree(n) == 1) && myoutdegree(n) == 1);
}

static void adjustlen(Agedge_t * e, Agsym_t * sym, int newlen)
{
    char buf[12];

    snprintf(buf, sizeof(buf), "%d", newlen);
    agxset(e, sym, buf);
}

static Agsym_t *bindedgeattr(Agraph_t * g, char *str)
{
    return agattr(g, AGEDGE, str, "");
}

static void transform(Agraph_t * g)
{
    Agnode_t *n;
    Agedge_t *e;
    char *str;
    Agsym_t *m_ix, *s_ix;
    int cnt, d;

    m_ix = bindedgeattr(g, "minlen");
    s_ix = bindedgeattr(g, "style");

    for (n = agfstnode(g); n; n = agnxtnode(g, n)) {
	d = myindegree(n) + myoutdegree(n);
	if (d == 0) {
	    if (ChainLimit < 1)
		continue;
	    if (ChainNode) {
		e = agedge(g, ChainNode, n, "", TRUE);
		agxset(e, s_ix, "invis");
		ChainSize++;
		if (ChainSize < ChainLimit)
		    ChainNode = n;
		else {
		    ChainNode = NULL;
		    ChainSize = 0;
		}
	    } else
		ChainNode = n;
	} else if (d > 1) {
	    if (MaxMinlen < 1)
		continue;
	    cnt = 0;
	    for (e = agfstin(g, n); e; e = agnxtin(g, e)) {
		if (isleaf(agtail(e))) {
		    str = agxget(e, m_ix);
		    if (str[0] == 0) {
			adjustlen(e, m_ix, (cnt % MaxMinlen) + 1);
			cnt++;
		    }
		}
	    }

	    cnt = 0;
	    for (e = agfstout(g, n); e; e = agnxtout(g, e)) {
		if (isleaf(e->node) || (Do_fans && ischainnode(e->node))) {
		    str = agxget(e, m_ix);
		    if (str[0] == 0)
			adjustlen(e, m_ix, (cnt % MaxMinlen) + 1);
		    cnt++;
		}
	    }
	}
    }
}


int agUnflatten(Agraph_t * g,  int doFans, int maxMinlen, int chainLimit) {
//    setting module parameters
    Do_fans = doFans;
    MaxMinlen = maxMinlen;
    ChainLimit = chainLimit;
    ChainSize = 0;
    ChainNode = 0;
// execute unflatten
    transform(g);
    return 0;
}
