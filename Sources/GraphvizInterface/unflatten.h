//
//  unflatten.h
//  SwiftGraphviz
//
//  Created by Klaus Kneupner on 13/02/2022.
//  Copyright © 2022 Klaus Kneupner. All rights reserved.
//

#ifndef unflatten_h
#define unflatten_h

#include "gvc.h"

int agUnflatten(Agraph_t * g, int doFans, int maxMinlen, int chainLimit, int chainSize);

#endif /* unflatten_h */
