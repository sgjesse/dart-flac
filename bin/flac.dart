import "dart:async";
import "dart:convert";
import "dart:io";

readFlac(File file) {
  bool nextMetadataBlockIsLast = false;
  int nextMetadataBlockType = -1;
  int nextMetadataBlockLength = -1;
  
  processMetadataBlock(data) {
    switch (nextMetadataBlockType) {
      case 0:
        print('STREAMINFO');
        break;
      case 1:
        print('PADDING');
        break;
      case 2:
        print('APPLICATION');
        break;
      case 3:
        print('SEEKTABLE');
        break;
      case 4:
        print('VORBIS_COMMENT');
        print(data);
        break;
      case 5:
        print('CUESHEET');
        break;
      case 6:
        print('PICTURE');
        break;
      default:
        print("Skipping metadata block type $nextMetadataBlockType");
    }
  }
  
  checkNextMetadataBlock(data) {
    if (!nextMetadataBlockIsLast) {
      int x = data.length - 4;
      nextMetadataBlockIsLast = data[x] & 0x80 != 0;
      nextMetadataBlockType = data[x] & 0x7f;
      nextMetadataBlockLength = 65536 * data[x + 1] + 256 * data[x + 2] + data[x + 3];
    }
  }
  
  readHeader(raf) {
    return raf.read(8).then((data) {
      checkNextMetadataBlock(data);
      return raf;
    });
  }

  readMetadataBlock(raf) {
    print("Reading $nextMetadataBlockType length $nextMetadataBlockLength");
    int extraLength = nextMetadataBlockIsLast ? 0 : 4;
    return raf.read(nextMetadataBlockLength + extraLength).then((data) {
      processMetadataBlock(data);
      if (!nextMetadataBlockIsLast) {
        checkNextMetadataBlock(data);
        return false;
      } else {
        return true;
      }       
    });
  }
  
  readMetaData(raf) {
    var completer = new Completer();
    r() {
      var last = nextMetadataBlockIsLast;
      readMetadataBlock(raf).then((done) => done ? completer.complete(null) : r());   
    }
    r();
    return completer.future;
  }
  
  file.open()
      .then(readHeader)
      .then(readMetaData)
      .then(print);
}
/*
 * 4 bytes fLaC
 * 4 byte METADATA_BLOCK_HEADER
 */
void main() {
  readFlac(new File("test.flac"));
  
  //print("Hello, World!");
}
