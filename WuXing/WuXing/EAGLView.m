//
//  EAGLView.m
//  WuXing
//
//  Created by tsuyoshi on 2013/11/26.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "EAGLView.h"

@implementation EAGLView {
    GLint _framebufferWidth;
    GLint _framebufferHeight;
    
    GLuint _defaultFramebuffer;
    GLuint _colorRenderbuffer;
    GLuint _depthRenderbuffer;
}

// You must implemtn thid method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    NSAssert([self.layer isKindOfClass:[CAEAGLLayer class]], @"unexpected layer class:%@", self.layer);
    CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
    layer.opaque = TRUE;
    layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                nil];
}

- (void) dealloc {
    [self deleteFramebuffer];
}

- (void)setContext:(EAGLContext *)newContext {
    if (_context != newContext) {
        [self deleteFramebuffer];
        _context = newContext;
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)createFramebuffer {
    if (!_context) {
        NSLog(@"no context!");
        return;
    }
    if (_defaultFramebuffer) {
        NSLog(@"already exists framebuffer");
        return;
    }
        
    [EAGLContext setCurrentContext:_context];
    
    //create default frame buffer
    glGenFramebuffers(1, &_defaultFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFramebuffer);
    
    //create color render buffer
    glGenRenderbuffers(1, &_colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    
    //create depth buffer
    glGenRenderbuffers(1, &_depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _framebufferWidth, _framebufferHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete frame buffer status:%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)deleteFramebuffer {
    if (!_context) {
        return;
    }
    [EAGLContext setCurrentContext:_context];
    if (_defaultFramebuffer) {
        glDeleteFramebuffers(1, &_defaultFramebuffer);
        _defaultFramebuffer = 0;
    }
    
    if (_colorRenderbuffer) {
        glDeleteRenderbuffers(1, &_colorRenderbuffer);
        _colorRenderbuffer = 0;
    }
    
    if (_depthRenderbuffer) {
        glDeleteRenderbuffers(1, &_depthRenderbuffer);
        _depthRenderbuffer = 0;
    }
}

- (void)setFramebuffer {
    if (!_context) {
        NSLog(@"no context!");
        return;
    }
    [EAGLContext setCurrentContext:_context];
    if (!_defaultFramebuffer) {
        [self createFramebuffer];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFramebuffer);
    glViewport(0, 0, _framebufferWidth, _framebufferHeight);
}

- (BOOL)presentFramebuffer {
    if (!_context) {
        return FALSE;
    }
    
    [EAGLContext setCurrentContext:_context];
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    BOOL ret = [_context presentRenderbuffer:GL_RENDERBUFFER];
    return ret;
}

- (void)layoutSubviews {
    //re-create when layout changed.
    [self deleteFramebuffer];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
