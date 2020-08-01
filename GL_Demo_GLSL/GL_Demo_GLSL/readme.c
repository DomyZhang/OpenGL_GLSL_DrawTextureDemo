

/*

 .vsh  代码解析
 
 
 
 attribute vec4 position;
 attribute vec2 texCoordinate;

 varying lowp vec2 varyTexCoordinate;

 void main() {
     
     varyTexCoordinate = texCoordinate;
     
     // gl_Position 内建变量 --> 顶点数据变换后的结果
     gl_Position = position;
 }

*/
 



/*
 
 .fsh 代码解析
 
 
 
 precision highp float;// 设置精度 --> 它以下默认使用高精度

 varying lowp vec2 varyTexCoordinate;// 默认高精度 但它使用低精度

 // 纹理
 uniform sampler2D colorMap;// sampler2D 采样器 --> 这里传过来的是纹理ID

 void main {
     
     // 拿到纹理对应坐标系啊的纹素 --> 纹素：纹理对应像素点的颜色值：例：120*120的纹理 其中一个像素的颜色
     // 高频使用的内建函数： texture2D( 纹理, 纹理坐标 ) --> 返回值：颜色值
     
     // 颜色值 temp拿到了像素点的各种值，可根据业务做各种处理
     lowp vec4 temp = texture2D(colorMap, varyTexCoordinate);
     
     // 内建变量 gl_FragColor --> 片元着色器代码执行后的 结果: 片元像素颜色
     gl_FragColor = temp;
     
 }


 // 片元着色器 代码 有多少个像素点就执行此代码多少次。
 // 性能压力？ GPU 来做

 
 */




