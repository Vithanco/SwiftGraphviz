//
//  builtins.c
//  VisualThinkingWithIBIS
//
//  Created by Klaus Kneupner on 30/04/2017.
//

#include "builtins.h" //

extern gvplugin_library_t gvplugin_dot_layout_LTX_library;
extern gvplugin_library_t gvplugin_neato_layout_LTX_library;
extern gvplugin_library_t gvplugin_core_LTX_library;
//extern gvplugin_library_t gvplugin_quartz_LTX_library;
//extern gvplugin_library_t gvplugin_visio_LTX_library;
//extern gvplugin_library_t gvplugin_lasi_LTX_library;
//extern gvplugin_library_t gvplugin_pango_LTX_library;

extern struct _dt_s * textfont_dict_open(GVC_t * gvc);

lt_symlist_t lt_preloaded_symbols[] = {
    { "gvplugin_core_LTX_library", (void*)(&gvplugin_core_LTX_library) },
    { "gvplugin_dot_layout_LTX_library", (void*)(&gvplugin_dot_layout_LTX_library) },
    { "gvplugin_neato_layout_LTX_library", (void*)(&gvplugin_neato_layout_LTX_library) },
//    { "gvplugin_quartz_LTX_library", (void*)(&gvplugin_quartz_LTX_library)},
    //    { "gvplugin_visio_LTX_library", (void*)(&gvplugin_visio_LTX_library)},
    //#ifdef HAVE_PANGOCAIRO
    //    { "gvplugin_pango_LTX_library", (void*)(&gvplugin_pango_LTX_library) },
    //#ifdef HAVE_WEBP
    //    { "gvplugin_webp_LTX_library", (void*)(&gvplugin_webp_LTX_library) },
    //#endif
    //#endif
    //#ifdef HAVE_LIBGD
    //    { "gvplugin_gd_LTX_library", (void*)(&gvplugin_gd_LTX_library) },
    //#endif
    { 0, 0 }
};



GVC_t * loadGraphvizLibraries(void) {
    
    GVC_t * gvc =  gvNEWcontext(&lt_preloaded_symbols[0], 0);
    textfont_dict_open(gvc);  // this is a workaround due to https://gitlab.com/graphviz/graphviz/issues/1520
    
    gvAddLibrary(gvc, &gvplugin_core_LTX_library);
    gvAddLibrary(gvc, &gvplugin_dot_layout_LTX_library);
    gvAddLibrary(gvc, &gvplugin_neato_layout_LTX_library);
   // gvAddLibrary(gvc, &gvplugin_quartz_LTX_library);
    //    gvAddLibrary(gvc, &gvplugin_visio_LTX_library);
    //    gvAddLibrary(gvc, &gvplugin_lasi_LTX_library);
 //   gvAddLibrary(gvc, &gvplugin_pango_LTX_library);
   
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
