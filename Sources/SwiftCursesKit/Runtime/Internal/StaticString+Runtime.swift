extension StaticString {
  var runtimeFunctionName: String {
    withUTF8Buffer { buffer in
      String(decoding: buffer, as: UTF8.self)
    }
  }
}
