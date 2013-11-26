//
//  MHTexture.cpp
//  WuXing
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#include "MHTexture.h"


GLuint MHTexture::createWithPixels(GLubyte *pixels, GLsizei width, GLsizei height) {
    GLuint texture;
    
    //テクスチャの生成
    glGenTextures(1, &texture);
    //テクスチャをターゲットにバインド
    glBindTexture(GL_TEXTURE_2D, texture);
    //拡大縮小フィルタの設定
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    //ピクセルデータをテクスチャに設定する
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    
    
    return texture;
}

void MHTexture::drawTexture(GLuint texture, GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha) {
    
    const GLfloat positions[] = {
        x - width, y - height, x + width, y - height,
        x - width, y + height, x + width, y + height
    };
    
    const GLfloat colors[] = {
        red, green, blue, alpha,
        red, green, blue, alpha,
        red, green, blue, alpha,
        red, green, blue, alpha
    };
    
    const GLfloat texCoords[] = {
        0.0f, 1.0f, 1.0f, 1.0f,
        0.0f, 0.0f, 1.0f, 0.0f
    };

    glVertexPointer(2, GL_FLOAT, 0, positions);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}
