//
//  STLCloudBrowserSTLViewController.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 11/2/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//


#include "stl.h"
#import "STLCloudBrowserIAPHelper.h"
#import "STLCloudBrowserSTLViewController.h"
#import "STLCloudBrowserUtils.h"

#define DEFAULT_SCALE 1.0
#define DEFAULT_ORTHO_FACTOR 1.5
#define DEFAULT_ZOOM 2.0
#define MAX_Z_ORTHO_FACTOR 20

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

typedef struct {
	GLfloat x;
	GLfloat y;
	GLfloat z;
} vector_t;

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface STLCloudBrowserSTLViewController() {
    BOOL productHasBeenPurchased;
    NSString *_STLFilepath;
    stl_t *stl_obj;
    BOOL stl_loaded;
    
    GLfloat *vertices;
    GLuint vertex_cnt;
    
    GLuint vertexArray;
    GLuint vertexBuffer;
    
    EAGLContext *gl_context;
    GLKBaseEffect *effect;
    
    float ortho_factor;
    float view_ratio;
    
    int point_cloud;
    
    float zoom;
    bool zoom_enabled;
    
    bool rotation_enabled;
    float _rotation;
    
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _rotMatrix;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    GLKQuaternion _quatStart;
    GLKQuaternion _quat;
    
    GLuint _program;
    GLint uniforms[NUM_UNIFORMS];

    BOOL low_memory;
    NSOperationQueue *operationQueue;
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer;
- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)recognizer;
- (IBAction)buyOptions:(id)sender;
- (IBAction)buyApp:(id)sender;
- (IBAction)restorePurchase:(id)sender;
- (void)hideButtons:(BOOL)state;
- (void)showAlertWithTitle:(NSString *)title Message:(NSString *)msg;
@end

@implementation STLCloudBrowserSTLViewController
@synthesize glview = _glview;
@synthesize warningLabel = _warningLabel;
@synthesize stlFile = _stlFile;
@synthesize drive = _drive;
@synthesize evaluationCopyLabel = _evaluationCopyLabel;
@synthesize loadActivityIndicator = _loadActivityIndicator;
@synthesize isLocalfile = _isLocalfile;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

GLKVector4 global_ambient_light = {0, 0, 0, 0};
GLKVector4 object_color = {150.0 / 255.0 , 150.0 / 255.0, 150.0 / 255.0, 1.0};
GLKVector4 light_ambient = {0.3, 0.3, 0.3, 0.0};
GLKVector4 light_diffuse = {0.5, 0.5, 0.5, 1.0};
GLKVector4 light_specular = {0.5, 0.5, 0.5, 1.0};

float mat_shininess = 10.0;
GLKVector4 mat_specular = { 0.5, 0.5, 0.5, 1.0 };

-(void)initDefaultParameters {
    productHasBeenPurchased = [STLCloudBrowserIAPHelper hasProductBeingPurchased];
    ortho_factor = DEFAULT_ORTHO_FACTOR;
    zoom =  DEFAULT_ZOOM;
    zoom_enabled = YES;
    point_cloud = 0;
    rotation_enabled = YES;
}

-(void)hideButtons:(BOOL)hide
{
    NSEnumerator *e = [self.navigationItem.rightBarButtonItems objectEnumerator];
    UIButton *button;
    
    while (button = [e nextObject]) {
        [button setEnabled:!hide];
    }
    
    self.navigationItem.hidesBackButton = hide;
    
    if (hide == NO) {
        [self.loadActivityIndicator stopAnimating];
    }
}

-(void)showAlertWithTitle:(NSString *)title Message:(NSString *)msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}


- (IBAction)buyOptions:(id)sender
{
    UIAlertView *alertView = [UIAlertView new];
    alertView.delegate = self;
    
    alertView.title = NSLocalizedString(@"APP_NAME", nil);
    [alertView addButtonWithTitle:NSLocalizedString(@"BUY", nil)];
    [alertView addButtonWithTitle:NSLocalizedString(@"RESTORE", nil)];
    [alertView addButtonWithTitle:NSLocalizedString(@"CANCEL", nil)];
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self buyApp:nil];
            break;
        case 1:
            [self restorePurchase:nil];
            break;
        default:
            break;
    }
}

- (IBAction)buyApp:(id)sender {
    NSLog(@"Buy App called\n");
    BOOL status = NO;
    [self.loadActivityIndicator startAnimating];
    status = [[STLCloudBrowserIAPHelper sharedHelper] buyProduct];
    
    if (status == NO) {
        [STLCloudBrowserUtils showErrorMessage:NSLocalizedString(@"BUY_PROBLEM", nil)];
        [self.loadActivityIndicator stopAnimating];
    } else {
        [self hideButtons:YES];
    }
}

- (IBAction)restorePurchase:(id)sender {
    NSLog(@"Restore purchase called\n");

    [self.loadActivityIndicator startAnimating];
    [[STLCloudBrowserIAPHelper sharedHelper] restoreCompletedTransactions];
    
    [self hideButtons:YES];
}


- (void)restoreCompletedTransactionsFinished:(NSNotification *)notification {
    [self showAlertWithTitle:NSLocalizedString(@"APP_NAME", nil)
                     Message:NSLocalizedString(@"RESTORATION_COMPLETE", nil)];
    
    [self hideButtons:NO];
}

- (void)restoreCompletedTransactionsFinishedWithError:(NSNotification *)notification {
    [self showAlertWithTitle:NSLocalizedString(@"APP_NAME", nil)
                     Message:NSLocalizedString(@"RESTORATION_FAILED", nil)];
    
    [self hideButtons:NO];
}

- (void)productPurchased:(NSNotification *)notification {
    zoom_enabled = YES;
    [self.evaluationCopyLabel setHidden:YES];
    [self.loadActivityIndicator stopAnimating];
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.rightBarButtonItems = nil;
    
    [self.view setNeedsDisplay];
}

- (void)productPurchaseFailed:(NSNotification *)notification {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.loadActivityIndicator stopAnimating];
    [self hideButtons:NO];
    
    SKPaymentTransaction * transaction = (SKPaymentTransaction *) notification.object;
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [self showAlertWithTitle:NSLocalizedString(@"ERROR", nil)
                         Message:transaction.error.localizedDescription];
    }
}

-(void)loadDefaultSettings {
    [self.warningLabel setHidden:YES];
}

-(void)saveDefaultSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs synchronize];
}

-(void)ortho_dimensions_min_x:(GLfloat *)min_x max_x:(GLfloat *)max_x
                        min_y:(GLfloat *)min_y max_y:(GLfloat *)max_y
                        min_z:(GLfloat *)min_z max_z:(GLfloat *)max_z
{
	GLfloat diff_x = stl_max_x(stl_obj) - stl_min_x(stl_obj);
	GLfloat diff_y = stl_max_y(stl_obj) - stl_min_y(stl_obj);
	GLfloat diff_z = stl_max_z(stl_obj) - stl_min_z(stl_obj);
    
    GLfloat max_diff = MAX(MAX(diff_x, diff_y), diff_z);
    
    *min_x = stl_min_x(stl_obj) - ortho_factor*max_diff;
	*max_x = stl_max_x(stl_obj) + ortho_factor*max_diff;
	*min_y = stl_min_y(stl_obj) - ortho_factor*max_diff;
	*max_y = stl_max_y(stl_obj) + ortho_factor*max_diff;
	*min_z = stl_min_z(stl_obj) - MAX_Z_ORTHO_FACTOR * ortho_factor*max_diff;
	*max_z = stl_max_z(stl_obj) + MAX_Z_ORTHO_FACTOR * ortho_factor*max_diff;
}

-(void)dirLoaded:(STLCloudBrowserDirectory*)dir status:(BOOL)boolStatus {
    return;
}

-(void)fileLoaded:(STLCloudBrowserFile*)file status:(BOOL)boolStatus {
    
    if (boolStatus == NO) {
         NSLog(@"STLView unable to download %@", file.drivePath);
        _warningLabel.text = NSLocalizedString(@"STL_DOWNLOAD_PROBLEM", nil);
    } else {
         NSLog(@"STLView downloaded %@ to %@", file.drivePath, file.localPath);
        [self loadSTL:file.localPath];
    }
    
    [self stlLoadComplete];
    [self.view setNeedsDisplay];
}

-(NSString*)latestSTLfile {
    return _stlFile.localPath;
}

-(IBAction)loadSTL:(NSString*)path {
    
    stl_loaded = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        const char *stl_file = [path UTF8String];
        stl_error_t err = STL_ERR_NONE;
        
        if ((stl_obj = stl_alloc()) == NULL) {
            NSLog(@"Problem allocating the STL object");
        }
        
        if (stl_obj && (err = stl_load(stl_obj, (char *)stl_file)) != STL_ERR_NONE) {
            NSLog(@"Problem loading the STL file err = %d", err);
        }
        
        if (err == STL_ERR_NONE) {
            vertex_cnt = stl_vertex_cnt(stl_obj);
        }
        
        if ((err == STL_ERR_NONE) && (err = stl_vertices(stl_obj, &vertices)) != STL_ERR_NONE) {
            NSLog(@"Problem get the vertices for the object = %d", err);
        }
        
        if (err == STL_ERR_NONE) {
            stl_loaded = YES;
        }
        
    } else {
        NSLog(@"%@ file not found", _STLFilepath);
    }
}

-(void)stlLoadComplete {
    
    [_loadActivityIndicator stopAnimating];
    NSLog(@"Unhiding back button");
    self.navigationItem.hidesBackButton = NO;
        
    if (stl_loaded == NO) {
        [_glview setNeedsDisplay];
        self.warningLabel.text = NSLocalizedString(@"STL_INVALID_FILE_MESSAGE", nil);
        [self.warningLabel setHidden:NO];
        return;
    }
    
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:2];
    
    if (productHasBeenPurchased == NO) {
        UIButton *buyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [buyButton setFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
        [buyButton addTarget:self action:@selector(buyOptions:) forControlEvents:UIControlEventTouchUpInside];
        [buyButton setImage:[UIImage imageNamed:@"cart.png"] forState:UIControlStateNormal];
        UIBarButtonItem *buyButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buyButton];
        [buttons addObject:buyButtonItem];
    }
    
    [self.navigationItem setRightBarButtonItems:buttons];
    [self initDraw];
    [self.glview setNeedsDisplay];
    [self.view setNeedsDisplay];
}

-(void)tearDownSTL {
    
    if (stl_loaded) {
        stl_free(stl_obj);
        stl_loaded = false;
    }
    
    self.warningLabel.text = @"";
    [self.warningLabel setHidden:YES];
}

-(void)initGestureRecognizers {
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc]
                                                   initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [_glview addGestureRecognizer:doubleTapRecognizer];
    
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handlePinch:)];
    [_glview addGestureRecognizer:pinchRecognizer];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    _anchor_position = [self projectOntoSurface:_anchor_position];
    
    _current_position = _anchor_position;
    _quatStart = _quat;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    
    float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(1, 0, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(0, 1, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
    _current_position = GLKVector3Make(location.x, location.y, 0);
    _current_position = [self projectOntoSurface:_current_position];
    
    [self computeIncremental];
    [_glview setNeedsDisplay];
}

- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    point_cloud = point_cloud ? 0 : 1;
    [_glview setNeedsDisplay];
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    static float initialZoom;
    
    if (zoom_enabled == YES) {
        if (recognizer.state == UIGestureRecognizerStateBegan)
        {
            initialZoom = zoom;
        }
        
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            zoom = [recognizer scale] * initialZoom;
            [_glview setNeedsDisplay];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.warningLabel.text = @"";
    [self.warningLabel setHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.drive.delegate = self;
    self.glview.delegate = self;
    
    [self initDefaultParameters];
    [self initGestureRecognizers];
    [self loadDefaultSettings];
           
    low_memory = NO;
    
    self.navigationItem.title = NSLocalizedString(@"APP_NAME", nil);

    if (self.isLocalfile == NO) {
        self.navigationItem.hidesBackButton = YES;
    }
    
    if (productHasBeenPurchased == YES) {
        [self.evaluationCopyLabel setHidden:YES];
    }
    
    [_loadActivityIndicator startAnimating];
    [self.drive startLoadingFile:self.stlFile];
    [self.view setNeedsDisplay];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:kProductPurchasedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(productPurchaseFailed:) name:kProductPurchaseFailedNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(restoreCompletedTransactionsFinished:)
                                                 name:kProductRestoreCompletedTransactionsFinished
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(restoreCompletedTransactionsFinishedWithError:)
                                                 name:kProductRestoreCompletedTransactionsFailedWithError
                                               object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.navigationController == nil) {
        [self tearDownGL];
        [self tearDownSTL];
    }
}

-(void)setViewPort {
    GLfloat min_x, min_y, min_z, max_x, max_y, max_z;
    
    [self ortho_dimensions_min_x:&min_x
                           max_x:&max_x
                           min_y:&min_y
                           max_y:&max_y
                           min_z:&min_z
                           max_z:&max_z];
    
    _projectionMatrix = GLKMatrix4MakeOrtho(min_x,
                                            max_x,
                                            min_y,
                                            max_y,
                                            min_z,
                                            max_z);
    
    _rotMatrix = GLKMatrix4Identity;
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatStart = GLKQuaternionMake(0, 0, 0, 1);
}

-(void)setupBuffers {
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER,  6*sizeof(float)*stl_vertex_cnt(stl_obj), vertices,
                 GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_TRUE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
}

-(void)setupGL {
    CGRect bounds = _glview.frame;
    float width = bounds.size.width;
    float height = bounds.size.height;
    view_ratio = MAX(width, height) / MIN(width, height);
    
    [self loadShaders];
    [self setViewPort];
    [self setupBuffers];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:gl_context];
    
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteVertexArraysOES(1, &vertexArray);
    
    effect = nil;
}

-(void)initDraw {
    
    gl_context = nil;
    gl_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!gl_context) {
        NSLog(@"Failed to create ES context");
        return;
    }
    
    [EAGLContext setCurrentContext:gl_context];
    effect = [[GLKBaseEffect alloc] init];
    
    _glview.userInteractionEnabled = YES;
    _glview.context = gl_context;
    _glview.delegate = self;
    
    [self setupGL];
}

- (GLKVector3) projectOntoSurface:(GLKVector3) touchPoint
{
    float radius = self.view.bounds.size.width/3;
    GLKVector3 center = GLKVector3Make(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);
    GLKVector3 P = GLKVector3Subtract(touchPoint, center);
    
    // Flip the y-axis because pixel coords increase toward the bottom.
    P = GLKVector3Make(P.x, P.y * -1, P.z);
    
    float radius2 = radius * radius;
    float length2 = P.x*P.x + P.y*P.y;
    
    if (length2 <= radius2)
        P.z = sqrt(radius2 - length2);
    else
    {
        /*
         P.x *= radius / sqrt(length2);
         P.y *= radius / sqrt(length2);
         P.z = 0;
         */
        P.z = radius2 / (2.0 * sqrt(length2));
        float length = sqrt(length2 + P.z * P.z);
        P = GLKVector3DivideScalar(P, length);
    }
    
    return GLKVector3Normalize(P);
}

- (void)computeIncremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    
    // TODO: Do something with Q_rot...
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
}

-(void)applyTransformations {
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(((stl_max_x(stl_obj) + stl_min_x(stl_obj))/2),
                                                           ((stl_max_y(stl_obj) + stl_min_y(stl_obj))/2),
                                                           ((stl_max_z(stl_obj) + stl_min_z(stl_obj))/2));
    
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, zoom, zoom/view_ratio, zoom);
    
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(_quat);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix,
                                          -((stl_max_x(stl_obj) + stl_min_x(stl_obj))/2),
                                          -((stl_max_y(stl_obj) + stl_min_y(stl_obj))/2),
                                          -((stl_max_z(stl_obj) + stl_min_z(stl_obj))/2));
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(_projectionMatrix, modelViewMatrix);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(135.0 / 255, 206.0 / 255.0, 250.0 / 255.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if(stl_loaded == NO || low_memory == YES) {
        return;
    }
    
    glBindVertexArrayOES(vertexArray);
    [self applyTransformations];
    
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(point_cloud ? GL_LINES: GL_TRIANGLES, 0, stl_vertex_cnt(stl_obj));
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"SimpleVertex" ofType:@"glsl"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"SimpleFragment" ofType:@"glsl"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
