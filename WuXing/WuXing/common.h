//
//  common.h
//  WuXing
//
//  Created by tsuyoshi on 2013/11/26.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#ifndef WuXing_common_h
#define WuXing_common_h

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __OBJC__
extern EAGLContext* glContext;
#endif
    
extern GLuint glProgram;
extern GLuint glUniformTexture, glUniformMatrix, glUniformColor;

#ifdef __cplusplus
}
#endif


#endif
