//
//  TMSGLKView.m
//  TMSGLTestDemo
//
//  Created by TMMMS on 2021/6/18.
//

#import "TMSGLKView.h"
#import <OpenGLES/ES2/gl.h>
#import <AVFoundation/AVFoundation.h>

@interface TMSGLKView ()
{
    //继承于CALayer，是在iOS上用于绘制OpenGL ES的图层类
    CAEAGLLayer *_eaglLayer;
    //上下文
    EAGLContext *_context;
    //渲染缓冲区
    GLuint _renderBuffer;
    //帧缓冲区
    GLuint _frameBuffer;
    //Program
    GLuint _program;
}
@end

@implementation TMSGLKView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self == [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    
    //创建图层
    [self createLayer];
    
    //创建图形的上下文
    [self createContext];
    
    //清空缓存区
    [self cleanUpBuffers];
    
    /*
     必须是先有渲染缓存区，再有帧缓存区，因为renderbuffer才是真的缓存颜色，模版，深度的地方
     frameBuffer是附着点！！！相当于只是管理着renderbuffer
     */
    
    //设置渲染缓存区
    [self setUpRenderBuffer];
    
    //设置帧缓存区
    [self setUpFrameBuffer];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    [self render];
}

#pragma mark - 创建图层
- (void)createLayer {
    
    //要重写layerClass，把图层强转成CAEAGLLayer类型，并赋值给eaglLayer
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    
    //设置layer绘制的描述属性
    /*
     kEAGLDrawablePropertyRetainedBacking表示绘图表面显示后，是否保留其内容。(一般是不保留，下一次重新绘制)
     
     kEAGLDrawablePropertyColorFormat 可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     
     kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
     kEAGLColorFormatRGB565：16位RGB的颜色，
     kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     */
    _eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@false,kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - 设置图层上下文
- (void)createContext {
    
    //初始化上下文
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!_context) {
        NSLog(@"上下文创建失败");
        return;
    }
    
    //设置当前上下文
    [EAGLContext setCurrentContext:_context];
    
}

#pragma mark - 清空缓存区
- (void)cleanUpBuffers {
    
    // 设置缓存区之前先清空一下缓存区
    
    //清空renderBuffer
    glDeleteBuffers(1, &_renderBuffer);
    _renderBuffer = 0;
    
    //清空frameBuffer
    glDeleteBuffers(1, &_frameBuffer);
    _frameBuffer = 0;
     
}

#pragma mark - 申请并设置渲染缓冲区
- (void)setUpRenderBuffer {
    
    //定义一个存储缓存区的ID的变量
    GLuint renderBufferID;
    
    //申请缓存区，并将其身份ID赋值
    glGenRenderbuffers(1, &renderBufferID);
    
    //将渲染缓存区的身份ID赋值给属性来保存
    _renderBuffer = renderBufferID;
    
    //根据缓存区ID绑定缓存区的类型
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    //将刻绘制对象，也即是我们的CAEAGLLayer图层对象，绑定到RenderBuffer对象
    BOOL result = [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    if (!result) {
        NSLog(@"绘制图层和渲染缓存区绑定失败");
    }
    
}

#pragma mark - 申请并设置帧缓存区
- (void)setUpFrameBuffer {
    
    //定义保存帧缓存区ID的对象
    GLuint frameBufferID;
    
    //申请帧缓存区并将身份ID赋值
    glGenFramebuffers(1, &frameBufferID);
    
    //将得到的frameBufferID赋值给属性
    _frameBuffer = frameBufferID;
    
    //根据缓存区ID，把它的绑定到对应的缓存区类型
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    //把framebuffer和renderbuffer绑定在一起
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
}

#pragma mark - 加载着色器，链接并使用程序program
- (void)loadShaderAndLinkUseProgram {
    
    //读取顶点着色器和片元着色器的程序文件
    NSString *vshFile = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    NSString *fshFile = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    
    //加载着色器文件，并创建最终的程序
    _program = [self loadVertex:vshFile Fragment:fshFile];
    
    //链接程序
    glLinkProgram(_program);
    
    //获取链接的状态
    GLint linkStatus;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkStatus);
    //判断程序是否链接成功
    if (linkStatus == GL_FALSE) {
        //失败的话要拿取错误信息，存储在数组里面
        //定义错误信息数组GLChar类型数组，直接分配内存空间
        GLchar message[512];
        //参数：(1)程序 (2)错误信息的内存大小 (3)从哪里开始放 (4)错误信息放在哪里，直接写message一样，数组首地址
        glGetProgramInfoLog(_program, sizeof(message), 0, &message[0]);
        NSLog(@"程序链接失败，失败信息 : %@",[NSString stringWithUTF8String:message]);
        return;
    }
    
    //使用Program
    glUseProgram(_program);
    
}

#pragma mark - 处理顶点数据
- (void)setupVBOs {
    
    UIImage *image = [UIImage imageNamed:@"texture.jpg"];
    
    CGRect realRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.bounds);
    
    // 按照图片比例与屏幕比例进行适配
    CGFloat widthRatio = realRect.size.width/self.bounds.size.width;
    CGFloat heightRatio = realRect.size.height/self.bounds.size.height;
    
    // 绘制三角形序列的方式，共有3种方式，此处只列举其中两种
    //设置顶点坐标数组
    GLfloat vertexArr[] = {

        widthRatio,-heightRatio,0.f,   1.f,0.f,
        -widthRatio,heightRatio,0.f,   0.f,1.f,
        -widthRatio,-heightRatio,0.f,  0.f,0.f,

        widthRatio,heightRatio,0.f,    1.f,1.f,
        -widthRatio,heightRatio,0.f,   0.f,1.f,
        widthRatio,-heightRatio,0.f,   1.f,0.f

    };
    
//    // GL_TRIANGLE_STRIP
//    GLfloat vertexArr[] = {
//        -widthRatio, -heightRatio, 0, 0.f, 0.f,  //左下
//        widthRatio,  -heightRatio, 0, 1.f, 0.f,  //右下
//        -widthRatio, heightRatio,  0, 0.f, 1.f,  //左上
//        widthRatio,  heightRatio,  0, 1.f, 1.f   //右上
//    };
    
    // 图片填充满整个窗口，图片会被拉伸
//    GLfloat vertexArr[] = {
//
//        1,-1.f,0.f,   1.f,0.f,
//        -1,1.f,0.f,   0.f,1.f,
//        -1,-1,0.f,  0.f,0.f,
//
//        1.f,1.f,0.f,    1.f,1.f,
//        -1.f,1.f,0.f,   0.f,1.f,
//        1.f,-1.f,0.f,   1.f,0.f
//
//    };
    
    //处理顶点信息
    //定义变量存储顶点缓存区ID
    GLuint vertexID;
    
    //申请顶点缓存区，并将ID赋值
    glGenBuffers(1, &vertexID);
    
    //绑定缓存区ID和对应的缓存区类型
    glBindBuffer(GL_ARRAY_BUFFER, vertexID);
    
    //将顶点数据从CPU拷贝到GPU中，也就是内存数据放入显存
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexArr), vertexArr, GL_DYNAMIC_DRAW);
    
    //将顶点数据通过Program，传入到顶点着色器的position中,并返回一个属性变量的位置
    //第二个参数必须和顶点着色器中的顶点坐标属性字母完全一致
    GLuint position = glGetAttribLocation(_program, "position");
    
    //打开属性通道，并且以合适的格式传输从buffer中读取顶点数据
    glEnableVertexAttribArray(position);
    
    //设置顶点坐标读取方式
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
}

#pragma mark - 设置纹理信息
- (void)setupTextureInfo {
    
    //将纹理坐标通过Program传入到顶点和片元着色器，同样的，字母名称必须和着色器中定义的变量完全一致
    GLuint textCoord = glGetAttribLocation(_program, "textCoordinate");
    
    //打开属性通道，传输纹理坐标
    glEnableVertexAttribArray(textCoord);
    
    //设置纹理坐标的读取方式
    glVertexAttribPointer(textCoord, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    
    //加载纹理
    [self loadTexture:@"texture.jpg"];
    
    //设置纹理采样器
    //参数:
    //(1). 第一个是得到纹理的ID索引的位置，因为纹理是不经常改变的，所以用Uniform通道
    //(2). 第几个纹理
    glUniform1i(glGetUniformLocation(_program, "colorMap"), 0);
    
}

#pragma mark - 加载着色器shader，并返回Program信息
- (GLuint)loadVertex:(NSString *)vertexFile Fragment:(NSString *)fragmentFile {
    
    //定义两个临时的着色器变量
    GLuint vertextShader, fragmentShader;
    
    //创建程序
    GLuint program = glCreateProgram();
    
    //编译顶点着色器和片元着色器程序
    //参数：
    //(1). 编译完成后的着色器的内存地址
    //(2). 编译的是哪个着色器，也就是着色器的类型。
    //(3). 着色器文件的项目路径
    //编译顶点着色器
    [self compileShader:&vertextShader type:GL_VERTEX_SHADER file:vertexFile];
    //编译片元着色器
    [self compileShader:&fragmentShader type:GL_FRAGMENT_SHADER file:fragmentFile];
    
    //把着色器都附着或者说链接上程序
    //附着顶点着色器
    glAttachShader(program, vertextShader);
    //附着片元着色器
    glAttachShader(program, fragmentShader);
    
    //用完了这两个临时的着色器变量，也就是附着到程序上面了，就可以删除掉了
    //删除顶点着色器
    glDeleteShader(vertextShader);
    //删除片元着色器
    glDeleteShader(fragmentShader);
    
    return program;
    
}

//编译着色器
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    
    //读取shader文件的路径
    NSString *shaderFile = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //因为glShaderSouce这个函数需要的是字符串类型的指针，所以这里转成C语言的字符串
    const GLchar *source = (GLchar *)[shaderFile UTF8String];
    
    //创建一个shader，并直接将创建的shader放入参数传过来的着色器内容(这里的*不是指的地址，是指的临时着色器的内容)
    *shader = glCreateShader(type);
    
    //将着色器源码附着到着色器对象上
    //参数：
    //(1). shader，要编译的着色器对象(*shader)
    //(2). 着色器源码字符串的数量，就是用了几个字符串写的或者说承载的着色器源码
    //(3). 真正的着色器程序的源码，也就是vsh和fsh里面的。(这就是第二个参数说的那一个字符串的地址)
    //(4). 着色器源码字符串的长度，如果不知道或者说不确定，写NULL，NULL代表字符串的终止位
    glShaderSource(*shader, 1, &source, NULL);
    
    //将着色器源码编译成目标代码
    glCompileShader(*shader);
    
}

#pragma mark - 从图片中加载纹理
- (void)loadTexture:(NSString *)textureFile {
    
    //将UIImage类型的图片转换成CGImageRef，因为纹理最终需要的是像素位图，也就是要解压图片
    CGImageRef spriteImage = [UIImage imageNamed:textureFile].CGImage;
    
    //可以判断一下是否获得到了像素位图
    if (!spriteImage) {
        NSLog(@"解压缩图片失败 : %@",textureFile);
        //非正常运行程序导致程序退出。exit(0)是正常运行程序导致退出
        exit(1);
    }
    
    //成功拿到位图了，获取图片的宽高的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //获取图片字节数是多少  也就是图片面积 * 颜色通道数量(RGBA就是4个)
    //也可以用malloc,malloc(width * height * 4 * sizeof(GLubyte));
    //稍提一嘴，calloc就是在内存的动态存储区上，分配第一个参数个数量的，每个单位长度为第二个参数的大小的连续空间
    //返回值是指向分配起始地址的指针，分配失败的话，返回值是NULL
    //calloc会清空分配的内存，而malloc不会。所以自行选择
    GLubyte *spriteByte = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    //创建上下文
    //参数：
    //(1). 指向要渲染的绘制图像的地址
    //(2). bitmap(位图)的宽，单位是像素
    //(3). bitmap(位图)的高，单位是像素
    //(4). bitsPerComponent是指内存中，像素的每个组件的位数，比如32位的RGBA，那么每一个颜色位都是8
    //(5). bytesPerRow指的是bitmap每一行内存需要多少bit(位)内存
    //(6). space指的是bitmap使用的颜色空间，可以通过CGImageGetColorSpace()获取
    //(7). bitmapInfo是枚举类型，CGImageAlpahInfo
    CGContextRef spriteContext = CGBitmapContextCreate(spriteByte, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    //在上下文上把图片绘制出来
    //定义变量，存储位图的尺寸CGRect
    CGRect rect = CGRectMake(0, 0, width, height);
    
    //使用默认的方法绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //绘制完成后就可以释放上下文了
    CGContextRelease(spriteContext);
    
    //绑定纹理到默认的纹理ID,因为glUniform里面也设置的0
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //设置纹理属性，这里就不多说了，可以参考OpenGL的文章，里面有纹理的属性设置
    //参数:
    //(1). 纹理维度
    //(2). 要设置的纹理属性的名字
    //(3). 要设置的纹理属性的参数
    //这里要设置纹理过滤方式和环绕方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //要转一下图片宽高的类型，不然会提示，毕竟一个是unsigned的size_t，但是载入纹理要的是int_32
    float tWidth = width,tHeight = height;
    
    //载入2D纹理
    //https://www.jianshu.com/p/4e2bb76e31c3  这里有解释
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, tWidth, tHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteByte);
    
    //图片数据也用完了，可以释放了
    free(spriteByte);
    
}

#pragma mark - 渲染并呈现
- (void)render {
    
    //设置背景色
    glClearColor(.0f, .0f, .0f, 1.f);
    
    //清空一下缓冲区
    glClear(GL_COLOR_BUFFER_BIT);
    
    //设置窗口大小
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //加载着色器，链接program，使用program
    [self loadShaderAndLinkUseProgram];
    
    //设置顶点
    [self setupVBOs];
    
    //处理纹理信息
    [self setupTextureInfo];
    
    //绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //将渲染缓冲区(RenderBuffer)上的内容渲染到屏幕上
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
}

- (void)dealloc {
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }

    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    NSLog(@"%@-dealloc", NSStringFromClass(self.class));
}

@end
