//
//  builtins.h
//  VisualThinkingWithIBIS
//
//  Created by Klaus Kneupner on 01/05/2017.
//  Copyright © 2017 Klaus Kneupner. All rights reserved.
//

#ifndef builtins_h
#define builtins_h

#include "gvplugin.h" //
#include "gvc.h"

GVC_t * loadGraphvizLibraries(void) ;

///NODES
pointf nd_coord(Agnode_t* n);
double nd_width(Agnode_t* n);
double nd_height(Agnode_t* n);


///EDGES
short ed_count(Agedge_t* e);
textlabel_t* ed_label(Agedge_t* e);
textlabel_t* ed_head_label(Agedge_t* e);
textlabel_t* ed_tail_label(Agedge_t* e);
pointf* ed_lp(Agedge_t* n);
pointf* ed_head_lp(Agedge_t* n);
pointf* ed_tail_lp(Agedge_t* n);
pointf* ed_xlp(Agedge_t* e);
pointf ed_headPort_pos(Agedge_t* e);
pointf ed_tailPort_pos(Agedge_t* e);
char* ed_label_text(Agedge_t* e);
char* ed_head_label_text(Agedge_t* e);
char* ed_tail_label_text(Agedge_t* e);

///GRAPHS
boxf gd_bb(Agraph_t* g);
textlabel_t* gd_label(Agraph_t* g);
pointf* gd_lp(Agraph_t* g);
pointf* gd_lsize(Agraph_t* g);
char* gd_label_text(Agraph_t* g);



#endif /* builtins_h */
