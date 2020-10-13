import Qt3D.Core 2.15
import Qt3D.Render 2.15

Entity {
    property var material
    property alias buffer: buf
    property alias count: attr.count

    property alias primitiveType: geometryRenderer.primitiveType

    GeometryRenderer{
        id: geometryRenderer

        // [[x y] [x y]]
        // [y1, y2, y3]
        primitiveType: GeometryRenderer.LineStrip
        instanceCount: 1


        geometry: Geometry {
            // Workaround for surpressing warnings
            boundingVolumePositionAttribute: dummy

            attributes: [Attribute {
                id: attr
                attributeType: Attribute.VertexAttribute
                vertexBaseType: Attribute.Float
                vertexSize: 1
                byteOffset: 0
                byteStride: 4
                count: 4096
                name: "vertexPosition"


                buffer : Buffer {
                    id: buf
                    type: Buffer.VertexBuffer
                    data: new Float32Array(new Array(4096).fill(0))
                }
            }, Attribute {
                id: dummy
                attributeType: Attribute.VertexAttribute
                vertexBaseType: Attribute.Float
                vertexSize: 3
                byteOffset: 0
                byteStride: 12
                count: 3


                buffer : Buffer {
                    type: Buffer.VertexBuffer
                    data: new Float32Array(new Array(9))
                }
            }]

        }
    }
    components: [geometryRenderer, material]
}
