//
//  builtins.c
//  VisualThinkingWithIBIS
//
//  Created by Klaus Kneupner on 30/04/2017.
//

#include "builtins.h"

// Static plugin registration — used on all platforms.
// Both Apple (xcframework) and Linux (artifact bundle) link Graphviz statically,
// so plugins must be registered explicitly rather than discovered dynamically.

extern gvplugin_library_t gvplugin_dot_layout_LTX_library;
extern gvplugin_library_t gvplugin_neato_layout_LTX_library;
extern gvplugin_library_t gvplugin_core_LTX_library;

// Signature must match Graphviz's real declaration (render.h): returns void.
// The old `struct _dt_s *` return was stale — harmless on native (linkers ignore
// return type) but fatal on wasm, where a call-site/definition signature mismatch
// traps at runtime. The return value is unused; this is called for its side effect
// (workaround for https://gitlab.com/graphviz/graphviz/issues/1520).
extern void textfont_dict_open(GVC_t * gvc);

lt_symlist_t lt_preloaded_symbols[] = {
    { "gvplugin_core_LTX_library", (void*)(&gvplugin_core_LTX_library) },
    { "gvplugin_dot_layout_LTX_library", (void*)(&gvplugin_dot_layout_LTX_library) },
    { "gvplugin_neato_layout_LTX_library", (void*)(&gvplugin_neato_layout_LTX_library) },
    { 0, 0 }
};

GVC_t * loadGraphvizLibraries(void) {
    GVC_t * gvc = gvNEWcontext(&lt_preloaded_symbols[0], 0);
    textfont_dict_open(gvc);  // workaround for https://gitlab.com/graphviz/graphviz/issues/1520

    gvAddLibrary(gvc, &gvplugin_core_LTX_library);
    gvAddLibrary(gvc, &gvplugin_dot_layout_LTX_library);
    gvAddLibrary(gvc, &gvplugin_neato_layout_LTX_library);

    return gvc;
}

pointf nd_coord(Agnode_t* n) {
    return ND_coord(n);
}

double nd_width(Agnode_t* n){
    return ND_width(n);
}
double nd_height(Agnode_t* n){
    return ND_height(n);
}


//////////// EDGES

short ed_count(Agedge_t* e) {
    return ED_count(e);
}


textlabel_t* ed_label(Agedge_t* e) {
    return ED_label(e);
}

double ed_label_fontsize(Agedge_t* e) {
    textlabel_t* label;
    label = ED_label(e);
    if (label) {
        return label->fontsize;
    }
    return 0;
}

textlabel_t* ed_head_label(Agedge_t* e) {
    return ED_head_label(e);
}

double ed_headlabel_fontsize(Agedge_t* e) {
    textlabel_t* label;
    label = ED_head_label(e);
    if (label) {
        return label->fontsize;
    }
    return 0;
}

textlabel_t* ed_tail_label(Agedge_t* e) {
    return ED_tail_label(e);
}

double ed_taillabel_fontsize(Agedge_t* e) {
    textlabel_t* label;
    label = ED_tail_label(e);
    if (label) {
        return label->fontsize;
    }
    return 0;
}


pointf* ed_lp(Agedge_t* e){
    textlabel_t* label;
    label = ED_label(e);
    if (label) {
        return &label->pos;
    }
    return 0;
}

char* ed_label_text(Agedge_t* e){
    textlabel_t* label;
    label = ED_label(e);
    if (label) {
        return label->text;
    }
    return 0;
}

char* ed_head_label_text(Agedge_t* e){
    textlabel_t* label;
    label = ED_head_label(e);
    if (label) {
        return label->text;
    }
    return 0;
}

char* ed_tail_label_text(Agedge_t* e){
    textlabel_t* label;
    label = ED_tail_label(e);
    if (label) {
        return label->text;
    }
    return 0;
}

pointf* ed_head_lp(Agedge_t* e){
    textlabel_t* label;
    label = ED_head_label(e);
    if (label) {
        return &label->pos;
    }
    return 0;
}

pointf* ed_tail_lp(Agedge_t* e){
    textlabel_t* label;
    label = ED_tail_label(e);
    if (label) {
        return &label->pos;
    }
    return 0;
}

pointf* ed_xlp(Agedge_t* e){
    textlabel_t* label;
    label = ED_xlabel(e);
    if (label) {
        return &label->pos;
    }
    return 0;
}

pointf ed_headPort_pos(Agedge_t* e){
    return ((Agedgeinfo_t*)AGDATA(e))->head_port.p;
}
pointf ed_tailPort_pos(Agedge_t* e){
    return ((Agedgeinfo_t*)AGDATA(e))->tail_port.p;
}



//////////// GRAPHS

boxf gd_bb(Agraph_t* g) {
    return GD_bb(g);
}

textlabel_t* gd_label(Agraph_t* g) {
    return GD_label(g);
}

pointf* gd_lp(Agraph_t* g) {
    textlabel_t* label;
    label = gd_label(g);
    if (label) {
        return &label->pos;
    }
    return 0;
}

pointf* gd_lsize(Agraph_t* g) {
    textlabel_t* label;
    label = gd_label(g);
    if (label) {
        return &label->space;
    }
    return 0;
}

char* gd_label_text(Agraph_t* g){
    textlabel_t* label;
    label = gd_label(g);
    if (label) {
        return label->text;
    }
    return 0;
}
