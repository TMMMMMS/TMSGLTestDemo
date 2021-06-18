//
//  SystemViewController.m
//  TMSGLTestDemo
//
//  Created by TMMMS on 2021/6/18.
//

#import "SystemViewController.h"

@interface SystemViewController()
{
    //上下文
    EAGLContext *_context;
    //苹果提供的着色器工具
    GLKBaseEffect *_baseEffect;
}
@end

@implementation SystemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //创建图形的上下文
    [self setupContext];
    
    //创建GLKView
    [self setupGLKView];
    
    //加载纹理信息
    [self loadTexture];
    
    //处理顶点数据
    [self setupVBOs];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupContext {
    
    // 初始化上下文
    _context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!_context) {
        NSLog(@"上下文创建失败");
    }
    
    // 设置当前上下文
    [EAGLContext setCurrentContext:_context];

}

- (void)setupGLKView {
    
    // 获取GLKView并设置context
    GLKView *view = [[GLKView alloc]initWithFrame:self.view.bounds context:_context];
    view.backgroundColor = [UIColor clearColor];
    view.delegate = self;
    [self.view addSubview:view];
    
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    glClearColor(0, 0, 0, 1);

}

- (void)loadTexture {
    
    //1.获取纹理图片路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"texture.jpg" ofType:nil];
    
    //2.设置纹理参数
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    //3.使用苹果GLKit提供GLKBaseEffect完成着色器工作
    _baseEffect = [[GLKBaseEffect alloc]init];
    _baseEffect.texture2d0.enabled = GL_TRUE;
    _baseEffect.texture2d0.name = textureInfo.name;
}

- (void)setupVBOs {
    
    // 设置顶点数组
    // 没有做适配，所以绘制出来的图片可能会变形
    GLfloat vertexData[] = {
        1, -0.5, 0.0f,    1.0f, 0.0f, //右下
        1, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -1, 0.5, 0.0f,    0.0f, 1.0f, //左上

        1, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -1, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -1, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    // 开辟顶点缓存区
    // 1.创建顶点缓存区标识符ID
    GLuint bufferID;
    glGenBuffers(1, &bufferID);
    // 2.绑定顶点缓存区.(明确作用)
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    // 3.将顶点数组的数据copy到顶点缓存区中(GPU显存中)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    // 打开属性通道，并且以合适的格式传输从buffer中读取顶点数
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 设置顶点坐标读取方式
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    // 打开属性通道，传输纹理坐标
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    // 设置纹理坐标的读取方式
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //1.清除颜色缓存区
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2.准备绘制
    [_baseEffect prepareToDraw];
    
    //3.开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
}

- (void)dealloc {
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    NSLog(@"%@-dealloc", NSStringFromClass(self.class));
}

@end
