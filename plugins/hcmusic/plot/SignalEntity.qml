import Qt3D.Core 2.15
import Qt3D.Render 2.15

Entity {
    property var material
    property alias buffer: buf
    property alias count: attr.count
    property int capacity: 0

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
                    data: new Float32Array(new Array(0).fill(0))
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

    function update(offset, bytes) {
        if(offset+bytes.length > capacity) {
            // new length will be nearest power of two >= offset+length
            let nl = Math.pow(2, Math.ceil(Math.log2(offset+bytes.length)))
            let nb = new Float32Array(nl);
            nb.set(new Float32Array(buf.data));
            nb.set(bytes, offset);
            nb.fill(0, offset+bytes.length)
            buf.data = nb;
            capacity = nl;

            attr.count = offset+bytes.length;
        } else {
            buf.updateData(offset*4, bytes);
            attr.count = Math.max(offset+bytes.length, attr.count);
        }
    }
}
