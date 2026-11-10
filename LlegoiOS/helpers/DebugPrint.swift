// Sombrea print()/debugPrint() de la librería estándar y los redirige a AppLog.debug:
// en Release no emiten nada y en Debug salen por os.Logger con el mensaje como privado.
// El terminator se ignora (os.Logger siempre escribe una línea por mensaje).
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    AppLog.debug(items.map { String(describing: $0) }.joined(separator: separator))
}

func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    AppLog.debug(items.map { String(reflecting: $0) }.joined(separator: separator))
}
