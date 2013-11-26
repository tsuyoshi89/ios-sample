//
//  MHTexture.h
//  WuXing
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#ifndef __WuXing__MHTexture__
#define __WuXing__MHTexture__



class MHTexture {
public:
    static GLuint createWithFile(const char *imagePath);
    
    
    static GLuint createWithPixels(GLubyte *pixels, GLsizei width, GLsizei height);
    

    static void drawTexture(GLuint texture, GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
};


#endif /* defined(__WuXing__MHTexture__) */
