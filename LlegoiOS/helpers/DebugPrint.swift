// Silences all print() calls in Release builds by shadowing the standard library function.
// Debug builds retain full console output.
#if !DEBUG
@inline(__always)
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
@inline(__always)
func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif
