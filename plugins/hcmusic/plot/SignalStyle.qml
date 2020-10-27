import Qt3D.Core 2.15
import Qt3D.Render 2.15
import QtQuick 2.12 as QQ2
import "."

Material {
    id: root
    property color mainColor: Qt.rgba(0.0, 0.0, 0.0, 1.0)
    property alias lineWidth: lw.value

    property ValueAxis xAxis: ValueAxis {min: -100; max: 100}
    property ValueAxis yAxis: ValueAxis {min: -100; max: 100}

    parameters: [
        Parameter {
            name: "mainColor"
            value: Qt.vector3d(root.mainColor.r, root.mainColor.g, root.mainColor.b)
        },
        Parameter {
            id: leftRange
            name: "leftRange"
            value: xAxis.min
        },
        Parameter {
            id: rightRange
            name: "rightRange"
            value: xAxis.max
        },
        Parameter {
            id: bottomRange
            name: "bottomRange"
            value: yAxis.min
        },
        Parameter {
            id: topRange
            name: "topRange"
            value: yAxis.max
        }

    ]
    //! [2]

    //! [0]

    LineWidth { id: lw; value: 2 }
    PointSize { id: ps; sizeMode: PointSize.Fixed; value: lw.value * 4 }

    effect: Effect {


        FilterKey {
            id: forward
            name: "renderingStyle"
            value: "forward"
        }

       techniques: [
            //! [3]
            // OpenGL 3.1

            Technique {
                filterKeys: [forward]
                graphicsApiFilter {
                    api: GraphicsApiFilter.OpenGL
                    profile: GraphicsApiFilter.CoreProfile
                    majorVersion: 3
                    minorVersion: 1
                }
                renderPasses: RenderPass {
                    shaderProgram: SignalShader.gl3ShaderComp.createObject(root)
                    renderStates: [
                        // MultiSampleAntiAliasing {}
                        lw,
                        ps
                    ]

                }
            },

            //! [3]
            // OpenGL 2.0

            Technique {
                filterKeys: [forward]
                graphicsApiFilter {
                    api: GraphicsApiFilter.OpenGL
                    profile: GraphicsApiFilter.NoProfile
                    majorVersion: 2
                    minorVersion: 1
                }
                renderPasses: RenderPass {
                    shaderProgram: SignalShader.gl2ShaderComp.createObject(root)
                    renderStates: [
                        lw,
                        ps
                    ]
                }
            }

        ]
    }
}
