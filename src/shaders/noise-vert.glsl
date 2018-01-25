#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;        // time in seconds

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

//scratchapixel memory saving technique
//instead of saving 256x256x256 values, save array of only 256 of random lattice values
//then index into it using permutation table(premade hashtable) for each dimension
//indices 0-255 are mixed up and saved to the first half of the permutation table(taken from ken perlin)
//those same values are copied to the second half of the table(for dimensions 2 and above)
//for example: for a 3D position in space, each component gets mapped to an int
//that int should be in the range 0-255 somehow (could normalize and mult by 255)
//then get the other 7 cube positions and fetch each random lattice value by doing
// permutation[permutation[permutation[posx] + posy] + posz]
//optimization idea: you could probably make the permutation array 0-255 then do & 0xFF on the sum result
//to save memory and increase the chances of getting the same cache line on subsequent reads
const int permTabe[512] = int[512]( 151,160,137,91,90,15,
   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
   190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
   88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
   77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
   102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
   135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
   5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
   223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
   129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
   251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
   49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
   151,160,137,91,90,15,

   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
   190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
   88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
   77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
   102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
   135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
   5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
   223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
   129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
   251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
   49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
   );

////scratchapixel: random direction in sphere
////printed to console and saved here to save on calcs
const vec3 latticeVals[256] = vec3[256](

vec3(0.00727041f, 0.963335f, 0.268202f),  vec3(-0.884132f, -0.37845f, 0.274019f),  vec3(0.321517f, -0.845779f, 0.425774f),  vec3(0.0648271f, -0.950795f, -0.302964f),
vec3(0.5295f, 0.217564f, 0.819937f),  vec3(-0.271293f, -0.933483f, 0.234541f),  vec3(-0.615555f, -0.747129f, -0.250778f),  vec3(0.0461704f, -0.0349421f, 0.998322f),
vec3(0.0648507f, -0.956964f, 0.282867f),  vec3(-0.0815315f, -0.642743f, -0.761731f),  vec3(0.921848f, -0.191739f, 0.336797f),  vec3(-0.249507f, -0.683976f, -0.68551f),
vec3(0.173146f, 0.932564f, -0.316773f),  vec3(0.990455f, 0.131338f, 0.0418227f),  vec3(-0.146783f, -0.385485f, 0.910965f),  vec3(0.830818f, -0.45208f, -0.324599f),

vec3(0.0182659f, 0.66926f, 0.742803f),  vec3(0.0993595f, 0.184835f, -0.977734f),  vec3(-0.224998f, -0.959162f, -0.171415f),  vec3(0.552467f, -0.0928238f, 0.82835f),
vec3(0.931159f, 0.151707f, -0.331553f),  vec3(-0.831895f, 0.544557f, -0.106815f),  vec3(-0.709814f, -0.210348f, -0.672249f),  vec3(0.782839f, -0.207459f, -0.58662f),
vec3(0.486433f, -0.250789f, -0.836952f),  vec3(0.375191f, 0.112165f, 0.920136f),  vec3(0.817955f, 0.103865f, -0.565827f),  vec3(-0.218586f, 0.952896f, -0.21026f),
vec3(-0.647232f, -0.762273f, -0.00558306f),  vec3(-0.718701f, 0.25017f, 0.648756f),  vec3(-0.627347f, -0.394534f, -0.671401f),  vec3(0.0215057f, -0.295136f, 0.955213f),

vec3(-0.841325f, -0.528471f, -0.113533f),  vec3(0.0916222f, -0.544749f, 0.833579f),  vec3(-0.306382f, 0.78189f, 0.542935f),  vec3(-0.926787f, 0.14486f, -0.346527f),
vec3(0.0338824f, -0.291554f, -0.955954f),  vec3(0.251758f, 0.88582f, 0.389795f),  vec3(-0.516198f, -0.609057f, 0.602154f),  vec3(0.302754f, -0.921036f, -0.245016f),
vec3(0.499552f, 0.236709f, 0.833317f),  vec3(-0.176147f, 0.84617f, -0.50296f),  vec3(-0.226548f, -0.585255f, -0.778558f),  vec3(0.0537729f, -0.89634f, -0.440095f),
vec3(0.00368655f, 0.351957f, 0.936009f),  vec3(0.814108f, -0.556861f, 0.164725f),  vec3(-0.00313186f, -0.904307f, 0.426871f),  vec3(-0.720903f, -0.228519f, 0.654276f),

vec3(0.891363f, 0.43049f, -0.141952f),  vec3(0.455505f, 0.793153f, -0.404257f),  vec3(-0.5474f, 0.378012f, -0.746632f),  vec3(-0.478329f, 0.276249f, -0.8336f),
vec3(-0.112616f, -0.316884f, -0.941755f),  vec3(0.387001f, 0.65449f, -0.649518f),  vec3(-0.813662f, 0.40146f, 0.420456f),  vec3(0.00197896f, 0.941901f, -0.335884f),
vec3(0.534276f, -0.62349f, 0.570797f),  vec3(0.693939f, 0.711241f, 0.112183f),  vec3(-0.979227f, 0.126933f, 0.158123f),  vec3(-0.553723f, 0.272791f, 0.786751f),
vec3(0.311534f, -0.769949f, 0.556888f),  vec3(0.928743f, -0.00850386f, 0.370626f),  vec3(0.187173f, 0.71899f, 0.669343f),  vec3(-0.647842f, 0.59968f, -0.46977f),

vec3(0.814023f, 0.579605f, 0.0377467f),  vec3(-0.122003f, -0.275265f, 0.953595f),  vec3(-0.689239f, -0.269874f, -0.672397f),  vec3(0.589487f, 0.803695f, -0.0811125f),
vec3(-0.248462f, -0.882659f, -0.398973f),  vec3(-0.827169f, 0.549361f, -0.118298f),  vec3(0.953227f, 0.0455255f, -0.298806f),  vec3(0.330646f, -0.845764f, 0.418756f),
vec3(0.725018f, 0.651149f, 0.224399f),  vec3(-0.746445f, 0.349073f, -0.56654f),  vec3(0.493486f, -0.0385772f, -0.868898f),  vec3(-0.203123f, -0.870172f, 0.448934f),
vec3(-0.583114f, 0.711364f, 0.392352f),  vec3(-0.955707f, -0.221882f, 0.193369f),  vec3(-0.0285002f, -0.0799257f, 0.996393f),  vec3(0.954924f, 0.291094f, -0.0581814f),

vec3(0.458142f, 0.0373383f, -0.888095f),  vec3(0.955725f, 0.211826f, -0.204252f),  vec3(0.188429f, -0.059843f, -0.980262f),  vec3(0.862648f, 0.195946f, 0.466309f),
vec3(0.111948f, 0.171829f, -0.978745f),  vec3(0.618185f, -0.723396f, 0.307483f),  vec3(-0.500109f, 0.865937f, -0.00665116f),  vec3(-0.095692f, -0.958061f, -0.270114f),
vec3(-0.152336f, -0.954116f, 0.257792f),  vec3(-0.327051f, 0.563227f, 0.758824f),  vec3(-0.933999f, -0.0291661f, -0.356082f),  vec3(0.547953f, 0.835361f, 0.0438132f),
vec3(0.713682f, -0.689927f, -0.121074f),  vec3(-0.53719f, -0.368114f, 0.758893f),  vec3(0.66459f, 0.672079f, -0.326542f),  vec3(0.508199f, -0.0621735f, -0.858992f),

vec3(-0.0863886f, 0.889579f, 0.448537f),  vec3(0.598319f, 0.502381f, -0.624202f),  vec3(0.687906f, -0.592523f, 0.419167f),  vec3(-0.902518f, -0.405635f, 0.144644f),
vec3(-0.619814f, -0.648604f, -0.44175f),  vec3(-0.443536f, 0.75993f, -0.475166f),  vec3(0.361397f, -0.828088f, 0.428558f),  vec3(-0.0346473f, -0.735239f, 0.676922f),
vec3(-0.655689f, -0.205182f, -0.726617f),  vec3(-0.0182952f, 0.756749f, -0.65345f),  vec3(0.110406f, -0.952685f, 0.2832f),  vec3(0.25272f, -0.95965f, -0.123306f),
vec3(-0.675151f, -0.696063f, 0.244269f),  vec3(0.767759f, -0.487651f, 0.415624f),  vec3(0.806436f, -0.506724f, -0.304781f),  vec3(0.517933f, 0.854231f, -0.0451056f),

vec3(-0.712149f, -0.692603f, -0.114646f),  vec3(0.966865f, 0.174814f, -0.186043f),  vec3(0.427738f, -0.519519f, -0.739689f),  vec3(-0.67099f, 0.258235f, 0.695045f),
vec3(-0.120734f, -0.451419f, 0.884106f),  vec3(0.437326f, -0.472934f, -0.764905f),  vec3(0.753597f, -0.473558f, 0.455889f),  vec3(0.628665f, 0.0503837f, -0.776043f),
vec3(-0.338725f, 0.406929f, 0.848336f),  vec3(-0.337859f, -0.197803f, 0.920177f),  vec3(0.578553f, 0.73388f, -0.355944f),  vec3(0.181554f, -0.943918f, -0.275785f),
vec3(0.197954f, 0.824964f, -0.529385f),  vec3(-0.510287f, -0.445011f, -0.735916f),  vec3(-0.869073f, 0.330636f, 0.367956f),  vec3(-0.449482f, -0.882663f, -0.137374f),

vec3(0.324326f, -0.313095f, -0.892628f),  vec3(-0.193608f, 0.975598f, 0.103556f),  vec3(0.340231f, -0.688338f, -0.640651f),  vec3(-0.110615f, 0.221307f, 0.96891f),
vec3(0.218225f, -0.366489f, -0.904469f),  vec3(0.516922f, -0.730896f, 0.445625f),  vec3(-0.54546f, 0.691697f, -0.473315f),  vec3(0.581819f, -0.812585f, 0.0345359f),
vec3(-0.13685f, 0.959204f, -0.247384f),  vec3(0.546854f, 0.354699f, -0.758379f),  vec3(-0.434047f, 0.166536f, -0.885364f),  vec3(0.00413703f, 0.656695f, -0.754145f),
vec3(-0.291225f, -0.373294f, 0.880818f),  vec3(0.231262f, -0.859892f, 0.455086f),  vec3(-0.162725f, 0.191237f, -0.967961f),  vec3(0.757383f, 0.313836f, -0.572607f),

vec3(0.538536f, 0.840016f, -0.0659647f),  vec3(-0.309097f, 0.146884f, -0.939619f),  vec3(0.0770558f, -0.0635308f, 0.995001f),  vec3(0.517959f, 0.449714f, 0.727651f),
vec3(-0.384973f, -0.73228f, -0.561748f),  vec3(0.0419224f, 0.998905f, -0.0207572f),  vec3(0.400816f, -0.915742f, 0.0276206f),  vec3(0.674809f, -0.549737f, -0.492364f),
vec3(0.662854f, -0.596881f, -0.45206f),  vec3(-0.627905f, 0.363075f, -0.688412f),  vec3(0.0253139f, -0.611196f, 0.791074f),  vec3(0.463155f, -0.292818f, 0.836508f),
vec3(-0.993557f, -0.109997f, -0.0273088f),  vec3(0.310672f, -0.0309722f, 0.950013f),  vec3(0.842299f, -0.297232f, 0.449651f),  vec3(0.567812f, -0.417893f, 0.709193f),

vec3(-0.691811f, -0.721331f, 0.0328529f),  vec3(0.465171f, 0.253814f, 0.848053f),  vec3(-0.461056f, 0.75892f, 0.459855f),  vec3(-0.00238052f, -0.991919f, -0.12685f),
vec3(0.798293f, -0.526658f, -0.292163f),  vec3(0.359809f, -0.188269f, 0.913834f),  vec3(0.632206f, -0.768043f, 0.102104f),  vec3(0.522286f, 0.137513f, -0.84161f),
vec3(-0.332519f, -0.326188f, 0.884891f),  vec3(0.458791f, -0.390815f, 0.797981f),  vec3(-0.0343677f, -0.649093f, -0.759932f),  vec3(0.655325f, 0.686776f, -0.314465f),
vec3(-0.799949f, 0.472792f, 0.369525f),  vec3(0.186072f, -0.955009f, 0.230944f),  vec3(-0.556633f, 0.0425051f, -0.82967f),  vec3(0.463779f, -0.659157f, 0.591965f),

vec3(0.227331f, -0.942107f, -0.246484f),  vec3(0.72631f, -0.676606f, 0.121154f),  vec3(0.12113f, 0.927636f, 0.353297f),  vec3(0.783196f, -0.269942f, -0.560121f),
vec3(-0.00763726f, 0.995607f, 0.0933191f),  vec3(-0.0751143f, 0.317028f, -0.945437f),  vec3(-0.967059f, 0.214198f, -0.137536f),  vec3(-0.289086f, -0.46783f, -0.835203f),
vec3(-0.548555f, 0.711202f, 0.439635f),  vec3(-0.624448f, -0.65393f, 0.42713f),  vec3(0.571022f, 0.0324826f, -0.820292f),  vec3(0.174992f, -0.814298f, -0.553441f),
vec3(-0.610522f, 0.738119f, 0.287131f),  vec3(-0.759245f, 0.624334f, -0.183723f),  vec3(-0.583336f, -0.46061f, -0.668997f),  vec3(-0.319113f, 0.224967f, 0.920628f),

vec3(-0.797372f, 0.0398913f, 0.602168f),  vec3(0.867242f, -0.391057f, -0.308164f),  vec3(-0.664142f, 0.498308f, 0.55732f),  vec3(-0.694531f, 0.690882f, 0.200772f),
vec3(-0.879562f, 0.328028f, -0.344627f),  vec3(0.49465f, 0.200773f, 0.845584f),  vec3(0.0803259f, 0.931131f, -0.355727f),  vec3(0.583823f, -0.785627f, -0.204797f),
vec3(0.991693f, -0.120399f, -0.0452624f),  vec3(0.898115f, -0.337981f, -0.281352f),  vec3(0.514822f, -0.0266444f, 0.856883f),  vec3(-0.569801f, -0.788417f, -0.231786f),
vec3(-0.606592f, -0.356294f, -0.710705f),  vec3(0.638114f, 0.769853f, -0.0116797f),  vec3(0.629452f, 0.445391f, -0.636723f),  vec3(0.297417f, -0.0565869f, -0.953069f),

vec3(0.038615f, -0.6857f, 0.726859f),  vec3(-0.773877f, -0.371301f, -0.513078f),  vec3(0.597302f, -0.692492f, 0.404579f),  vec3(-0.870129f, 0.37212f, -0.323113f),
vec3(-0.988258f, -0.144022f, 0.051017f),  vec3(-0.183363f, -0.848888f, 0.495748f),  vec3(0.782566f, 0.256435f, 0.567301f),  vec3(-0.0200946f, -0.909073f, 0.416153f),
vec3(0.686445f, -0.693323f, -0.219309f),  vec3(-0.0982159f, 0.240822f, -0.965587f),  vec3(0.270393f, 0.954733f, 0.123987f),  vec3(0.312878f, -0.0196236f, -0.949591f),
vec3(-0.690851f, 0.205842f, 0.693075f),  vec3(0.439361f, 0.142158f, 0.886991f),  vec3(0.71458f, 0.614252f, -0.334769f),  vec3(0.467687f, -0.329796f, 0.820063f),

vec3(0.904988f, 0.166007f, 0.391712f),  vec3(-0.852392f, 0.486144f, 0.192592f),  vec3(0.0819257f, -0.563762f, 0.821864f),  vec3(0.520078f, -0.578196f, -0.628656f),
vec3(0.573032f, -0.622061f, -0.533549f),  vec3(-0.0341981f, 0.966473f, -0.254482f),  vec3(0.625525f, 0.772111f, 0.112087f),  vec3(0.135563f, -0.98207f, 0.131004f),
vec3(-0.0694951f, 0.551607f, -0.831204f),  vec3(-0.676121f, -0.718593f, 0.162742f),  vec3(-0.0487213f, -0.0742775f, 0.996047f),  vec3(0.323093f, 0.939749f, 0.111727f),
vec3(0.31795f, 0.887596f, -0.333288f),  vec3(-0.117516f, 0.500563f, 0.857687f),  vec3(0.521354f, -0.567931f, 0.636903f),  vec3(0.234026f, -0.522126f, 0.820132f),

vec3(-0.294882f, -0.00535008f, 0.955519f),  vec3(0.96949f, 0.141524f, 0.200151f),  vec3(-0.11305f, 0.802081f, -0.586418f),  vec3(0.140081f, -0.0809432f, 0.986826f),
vec3(0.856857f, 0.460154f, -0.232497f),  vec3(0.955901f, 0.161155f, 0.245524f),  vec3(-0.629597f, -0.332675f, -0.702093f),  vec3(-0.576043f, -0.794079f, -0.193941f),
vec3(0.772861f, 0.175584f, -0.6098f),  vec3(-0.143251f, -0.785746f, 0.601733f),  vec3(-0.798608f, 0.311095f, -0.515213f),  vec3(0.691562f, -0.481613f, 0.538322f),
vec3(0.417491f, 0.907311f, 0.0498811f),  vec3(0.378208f, 0.0433136f, -0.924707f),  vec3(-0.0362783f, -0.75643f, -0.653067f),  vec3(-0.00490451f, -0.993475f, -0.113947f)

);

//scratchapixel: recommends two differnt smoothing techniques from ken perlin
vec3 smoothStepRemap(const vec3 t) { 
    //return t * t * t * (t * (t * 6.f - 15.f) + 10.f); 
    return t * t * (3.f - 2.f * t); 
}

//scratchapixel: we need the relative position inside the lattice cell,
//the base coordinate in the lattice to key off of, remember to perform a 
//smoothstep on the relative position components to smooth transitions
//between cells, use ken perlins permutation table to generate 1:1 mapping between
//any 256x256x256 coordinate and an index into our lattice values(our gradients)

float PerlinNoise3DSample(vec3 P) {
    //ultimately base coord (lower left) of lattice cell
    //can't just cast to int b/c negatives wouldn't floor correctly 
    //ex: int x = -1.4f; would be -1 when it should be -2 
    //for the purposes of snapping to lower left lattice coord
    vec3 floored = floor(P);

    //want the relative location inside the lattice cell
    P -= floored;

    //important lattice coordinates, ANDing lower bits is the same as modulus for powers of 2
    //modulus is expensive, worse than divide
    ivec3 p0Coord = ivec3(floored) & 255;
    ivec3 p1Coord = (p0Coord + 1) & 255;
    
    //remap uniform t value to warped t value to smooth the transitions
    vec3 P_remap = smoothStepRemap(P);

    //for 3D we need the eight corners of the cube we are in
    //nomenclature c000 means corner x=0 y=0 z=0 or the base coord p0Coord
    //where the numbers are offsets relative to the base corner
    //c111 means corner x=1 y=1 z=1 or the plus one coord p1Coord
    //TODO: try just getting the address instead of copying
    //left corners (lower x)
    vec3 c000 = latticeVals[permTabe[permTabe[permTabe[p0Coord.x]+p0Coord.y]+p0Coord.z]];
    vec3 c001 = latticeVals[permTabe[permTabe[permTabe[p0Coord.x]+p0Coord.y]+p1Coord.z]];
    vec3 c010 = latticeVals[permTabe[permTabe[permTabe[p0Coord.x]+p1Coord.y]+p0Coord.z]];
    vec3 c011 = latticeVals[permTabe[permTabe[permTabe[p0Coord.x]+p1Coord.y]+p1Coord.z]];
    //right corners (higher x)
    vec3 c100 = latticeVals[permTabe[permTabe[permTabe[p1Coord.x]+p0Coord.y]+p0Coord.z]];
    vec3 c101 = latticeVals[permTabe[permTabe[permTabe[p1Coord.x]+p0Coord.y]+p1Coord.z]];
    vec3 c110 = latticeVals[permTabe[permTabe[permTabe[p1Coord.x]+p1Coord.y]+p0Coord.z]];
    vec3 c111 = latticeVals[permTabe[permTabe[permTabe[p1Coord.x]+p1Coord.y]+p1Coord.z]];

    //generate components of vectors from corners to P
    float x0 = P.x, x1 = P.x - 1.0f; 
    float y0 = P.y, y1 = P.y - 1.0f; 
    float z0 = P.z, z1 = P.z - 1.0f; 
    
    //generate vectors from corners to P in lattice cell
    vec3 P000 = vec3(x0, y0, z0); 
    vec3 P100 = vec3(x1, y0, z0); 
    vec3 P010 = vec3(x0, y1, z0); 
    vec3 P110 = vec3(x1, y1, z0); 
    vec3 P001 = vec3(x0, y0, z1); 
    vec3 P101 = vec3(x1, y0, z1); 
    vec3 P011 = vec3(x0, y1, z1); 
    vec3 P111 = vec3(x1, y1, z1); 
    
    //dot the values at corners with the vectors from corners to point 
    //P in the lattice cell

    //4 edges along x axis
    float x_00 = mix(dot(c000, P000), dot(c100, P100), P_remap.x); 
    float x_10 = mix(dot(c010, P010), dot(c110, P110), P_remap.x); 
    float x_01 = mix(dot(c001, P001), dot(c101, P101), P_remap.x); 
    float x_11 = mix(dot(c011, P011), dot(c111, P111), P_remap.x); 
    
    //lerp previous dimension results together along y axis
    //4 previous values form 2 edges to lerp along
    float y_0 = mix(x_00, x_10, P_remap.y); 
    float y_1 = mix(x_01, x_11, P_remap.y); 
    
    //finally, lerp along z dimensions
    //2 previoius values form an edge to lerp along
    return mix(y_0, y_1, P_remap.z);
}

float PerlinNoise3D(vec3 P) {
    float result = 0.f; 
    int numlayer = 5; 
    float rateOfChange = 2.0f; 
    for (int i = 0; i < 5; ++i) { 
        // change in frequency and amplitude
        float freq = pow(rateOfChange, float(i));
        result += PerlinNoise3DSample(P * freq) / freq; 
    } 
    return result;
}
   
void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    //displace vs_Pos according to noise value
    vec3 vs_Pos3 = vec3(vs_Pos);
    float perlin = clamp(PerlinNoise3D(vs_Pos3*1.f), 0.f, 1.f);
    vec3 offset = (1.f/4.f)*perlin*vec3(vs_Nor);
    vec4 newPos = vec4(vs_Pos3 + offset, 1.f);

    //vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
    vec4 modelposition = u_Model * newPos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
