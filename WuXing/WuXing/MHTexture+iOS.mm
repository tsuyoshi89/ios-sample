//
//  MHTextureNative.m
//  WuXing
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHTexture.h"

GLuint MHTexture::createWithFile(const char *imagePath) {
    assert(imagePath);
    NSString *path = [NSString stringWithUTF8String:imagePath];

    //画像を読み込む
    CGImageRef image = [UIImage imageNamed:path].CGImage;
    
    if (!image) {
        NSLog(@"Error: %@ is not found.", path);
        return nil;
    }
    
    GLuint texture = 0;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    const size_t bytesPerPixels = 4;
    const size_t bitsPerComponent = 8;
    
    //画像を書き出すメモリを確保
    GLubyte *pixels = (GLubyte *)calloc(1, width * height * bytesPerPixels);
    if (pixels) {
    
        //メモリに描画するためのコンテキストを作成
        //AlphaPremultipliedLast：あらかじめAlpha合成をした値を保持することで高速化する
        CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, width * bytesPerPixels, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
        
        //imageをcontext全体に描画する
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        
        //生成したコンテキストの解放
        CGContextRelease(context);
    
        texture = createWithPixels(pixels,(GLsizei)width, (GLsizei)height);
        //ピクセルデータの解放
        free(pixels);
    }
    
    return texture;

}

