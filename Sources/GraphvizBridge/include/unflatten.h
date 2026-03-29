//
//  unflatten.h
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 13/02/2022.
//  Copyright © 2022 Klaus Kneupner. All rights reserved.
//

#ifndef unflatten_h
#define unflatten_h

#ifdef __APPLE__
#include "gvc.h"
#else
#include <graphviz/gvc.h>
#include <graphviz/cgraph.h>
#endif

int agUnflatten(Agraph_t * g, int doFans, int maxMinlen, int chainLimit);

#endif /* unflatten_h */
