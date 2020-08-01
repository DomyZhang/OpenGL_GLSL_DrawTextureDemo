//
//  MyGLSLView.m
//  GL_Demo_GLSL
//
//  Created by Domy on 2020/7/31.
//  Copyright © 2020 Domy. All rights reserved.
//


/*
 不采用 GLKBaseEffect，使用编译链接自定义的着色器（shader）。用简单的 glsl 语言来实现顶点、片元着色器，并图形进行简单的变换。
 思路:
 1.创建图层
 2.创建上下文
 3.清空缓存区
 4.设置RenderBuffer
 5.设置FrameBuffer
 6.开始绘制
 */

#import "MyGLSLView.h"

#import <OpenGLES/ES2/gl.h>


@interface MyGLSLView ()

@property (nonatomic, strong) CAEAGLLayer *myEGLLayer;// 图层
@property (nonatomic, strong) EAGLContext *myContext;// 上下文

@property (nonatomic, assign) GLuint myColorFrameBuffer;//
@property (nonatomic, assign) GLuint myColorRenderBuffer;// 渲染缓冲区

@property (nonatomic, assign) GLuint myProgram;

@end


@implementation MyGLSLView

+(Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews {
    
    // 1. 创建设置图层
    // 设置 layer
    self.myEGLLayer = (CAEAGLLayer *)self.layer;
    
    // 设置 scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // 设置属性
    /*
     kEAGLDrawablePropertyRetainedBacking：绘图表面显示后，是否保留其内容。
     kEAGLDrawablePropertyColorFormat：可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     
     kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
     kEAGLColorFormatRGB565：16位RGB的颜色，
     kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素，sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     */
//    self.myEGLLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@(NO),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    self.myEGLLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];

    
    // 2. 设置上下文
    self.myContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.myContext) {
        NSLog(@"create context failed!");
        return;
    }
    BOOL isSetSuccess = [EAGLContext setCurrentContext:self.myContext];
    if (!isSetSuccess) {
        return;
    }
    
    
    // 3. 清空缓冲区
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    
    
    // 4. 设置渲染缓冲区 renderBuffer
    // 生成缓冲区 ID
    GLuint rb;
    glGenRenderbuffers(1, &rb);
    self.myColorRenderBuffer = rb;
    // 绑定缓冲区
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    // 绑到 context: contect 与 eagllayer绑定在一起
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEGLLayer];
    
    
    // 5. 设置帧缓冲区 FrameBuffer
    glGenBuffers(1, &_myColorFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    // 渲染缓冲区 与 帧缓冲区绑在一起
    /*
     target：
     attachment：将 renderBuffer 附着到frameBuffer的哪个附着点上
     renderbuffertarget
     renderbuffer
     */
    //    glFramebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    
    
    
    // 开始绘制
    [self renderLayer];
    
}

- (void)renderLayer {
    
    glClearColor(0.7, 0.7, 0.7, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    /// 1. 设置视口
    CGFloat mainScale = [UIScreen mainScreen].scale;
    glViewport(self.frame.origin.x * mainScale, self.frame.origin.y * mainScale, self.frame.size.width * mainScale, self.frame.size.height * mainScale);
    
    /// 2. 读取着色器代码
    // 定义路径
    NSString *verPath = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragPath = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    /// 3. 加载着色器
    self.myProgram = [self loadShadersWithVertex:verPath Withfrag:fragPath];
    
    /// 4. 链接 program
    glLinkProgram(self.myProgram);
    // 获取连接状态
    GLint linkStatus;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {// 链接出错
        // 获取错误信息 log
        GLchar message[512];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return;
    }
    
    /// 5. 使用 program
    glUseProgram(self.myProgram);
    
    
    
    /// 6. 设置顶点、纹理坐标
    // 3个顶点坐标，2个纹理坐标
    GLfloat attrArr[] = {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
//    // 图片旋转方案二
//    // 纹理坐标反向对应
//    GLfloat attrArr[] = {
//            0.5f, -0.5f, -1.0f,     1.0f, 1.0f,
//            -0.5f, 0.5f, -1.0f,     0.0f, 0.0f,
//            -0.5f, -0.5f, -1.0f,    0.0f, 1.0f,
//
//            0.5f, 0.5f, -1.0f,      1.0f, 0.0f,
//            -0.5f, 0.5f, -1.0f,     0.0f, 0.0f,
//            0.5f, -0.5f, -1.0f,     1.0f, 1.0f,
//        };
    
    
    /// 7. copy 到顶点缓冲区
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    // 顶点数据 copy 到缓冲区
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);

    /// 8. 打开通道
    // 8.1 顶点
    // 获取通道 ID
    /*
     glGetAttribLocation(GLuint program, const GLchar *name)
     program:
     name: 给谁传 --> .vsh 的 position
     */
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    // 打开通道
    glEnableVertexAttribArray(position);
    // 读数据
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);

    // 8.2 纹理
    GLuint texture = glGetAttribLocation(self.myProgram, "textCoordinate");
    glEnableVertexAttribArray(texture);
    glVertexAttribPointer(texture, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    
    
    /// 9. 加载纹理
    [self loadTexture];
    
    /// 10. 设置纹理采样器
    glUniform1i(glGetUniformLocation(self.myProgram, "colorMap"), 0);
    
    
//    // 解决图片倒立 方案三
//    // 顶点着色器传入旋转矩阵对顶点进行旋转
//    [self rotateTextureImage];
    
    
    /// 11.  绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    // 12. 从渲染缓冲区显示到屏幕
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

// 解决图片倒立 方案三
-(void)rotateTextureImage {
    
    // 1. rotate等于shaderv.vsh中的uniform属性，rotateMatrix
    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
    
    // 2.获取渲旋转的弧度
    float radians = 180 * 3.14159f / 180.0f;
    // 3.求得弧度对于的sin\cos值
    float s = sin(radians);
    float c = cos(radians);
    
    // 4.因为在3D课程中用的是横向量，在OpenGL ES用的是列向量
    // 参考Z轴旋转矩阵
    GLfloat zRotation[16] = {
        c,-s,0,0,
        s,c,0,0,
        0,0,1,0,
        0,0,0,1
    };
    
    // 5.设置旋转矩阵
    /*
     glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value)
     location : 对于shader 中的ID
     count : 个数
     transpose : 转置
     value : 指针
     */
    glUniformMatrix4fv(rotate, 1, GL_FALSE, zRotation);
}



// 加载纹理
- (void)loadTexture {
    
    // 9.0 image 转为 CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:@"0001"].CGImage;
    // 图片是否获取成功
    if (!spriteImage) {
        NSLog(@"Failed to load image ");
        return;
    }
    // 获取图片宽高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    // 获取图片字节数 宽*高*4（RGBA）
    GLubyte *spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    
    // 创建上下文
    /*
     data：指向要渲染的绘制图像的内存地址
     width：bitmap 的宽度，单位为像素
     height：bitmap 的高度，单位为像素
     bitPerComponent：内存中像素的每个组件的位数，比如 32 位 RGBA，就设置为 8
     bytesPerRow：bitmap 的没一行的内存所占的比特数
     colorSpace：bitmap 上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

    // 在 CGContextRef 上 --> 将图片绘制出来
    /*
     CGContextDrawImage 使用的 Core Graphics 框架，坐标系与 UIKit 不一样。UIKit 框架的原点在屏幕的左上角，Core Graphics 框架的原点在屏幕的左下角。
     CGContextDrawImage(CGContextRef  _Nullable c, CGRect rect, CGImageRef  _Nullable image)
     c：绘图上下文
     rect：rect坐标
     image：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(spriteContext, rect, spriteImage);

    
    // 翻转图片 方案一
    // x、y 轴平移
    CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
    // y 平移
    CGContextTranslateCTM(spriteContext, 0, rect.size.height);
    // Y 轴方向 Scale -1 翻转
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    // 平移回原点位置处
    CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
    // 重绘
    CGContextDrawImage(spriteContext, rect, spriteImage);

    
    // 绘完 释放上下文
    CGContextRelease(spriteContext);
    
    // 9.1. 绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 9.2. 设置纹理属性
    /*
     glTexParameteri(GLenum target, GLenum pname, GLint param)
     target：纹理维度
     pname：线性过滤； 为s,t坐标设置模式
     param：wrapMode； 环绕模式
     */
    // 过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // 环绕方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    // 9.3 载入纹理
    /* 载入纹理 glTexImage2D
    参数1：纹理维度，GL_TEXTURE_2D
    参数2：mip贴图层次
    参数3：纹理单元存储的颜色成分（从读取像素图中获得）
    参数4：加载纹理宽度
    参数5：加载纹理的高度
    参数6：为纹理贴图指定一个边界宽度 0
    参数7、8：像素数据的数据类型, GL_UNSIGNED_BYTE无符号整型
    参数9：指向纹理图像数据的指针
    */
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

    // 9.4 释放 sprite
    free(spriteData);
}




// 加载着色器
// 顶点着色器 和 片元着色器 的代码传进来(.vsh  .fsh)
-(GLuint)loadShadersWithVertex:(NSString *)vert Withfrag:(NSString *)frag {
    
    // 1.定义 着色器
    GLuint verShader, fragShader;
    
    // 2.创建程序 program
    GLint program = glCreateProgram();// 创建一个空的程序对象
    
    // 3.编译着色器 --> 封装一个方法 compileShaderWithShader:
    [self compileShaderWithShader:&verShader shaderType:GL_VERTEX_SHADER filePath:vert];
    [self compileShaderWithShader:&fragShader shaderType:GL_FRAGMENT_SHADER filePath:frag];
    
    // 4.attach shader, 将shader附着到 程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //5.已附着好的 shader 删掉，避免不必要的内存占用
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;// 返回编译好的程序
}
// 编译着色器
/*
 shader: 着色器 ID
 type: 着色器类型
 path: 着色器代码文件路径
 */
- (void)compileShaderWithShader:(GLuint *)shader shaderType:(GLenum)type filePath:(NSString *)path {
    
    // 1.读取文件路径
    NSString *file = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    // NSString 转 C 的 char
    const GLchar *source = (GLchar *)[file UTF8String];
    
    // 2.创建对应类型的shader
    *shader = glCreateShader(type);
    
    // 3.读取着色器源码 将其附着到着色器对象上面
    /* params:
     shader: 要编译的着色器对象 *shader
     numOfStrings: 传递的源码字符串数量 1个
     参数3：strings: 着色器程序的源码（真正的着色器程序源码）
     参数4：lenOfStrings: 长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
     */
    //    glShaderSource(GLuint shader, GLsizei count, const GLchar *const *string, const GLint *length)
    glShaderSource(*shader, 1, &source,NULL);
    
    // 4. 编译
    glCompileShader(*shader);
}


@end
