pragma Singleton
import QtQuick 2.12
import Qt3D.Render 2.12

QtObject {
    id: shader
    
    property Component gl3ShaderComp: ShaderProgram {
        vertexShaderCode: loadSource(Qt.resolvedUrl('shaders/gl3/shader.vert')) 
        fragmentShaderCode: loadSource(Qt.resolvedUrl('shaders/gl3/shader.frag'))
    }
    

    property Component gl2ShaderComp: ShaderProgram {
        vertexShaderCode: loadSource(Qt.resolvedUrl('shaders/gl2/shader.vert')) 
        fragmentShaderCode: loadSource(Qt.resolvedUrl('shaders/gl2/shader.frag'))
    }
    

}