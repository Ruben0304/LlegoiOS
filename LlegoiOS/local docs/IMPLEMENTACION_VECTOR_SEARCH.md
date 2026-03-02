# Implementación de búsqueda vectorial local (on-device) en iOS

## 1. Objetivo
Implementar búsqueda vectorial **100% local (on-device)** en iOS:
1. Indexar textos en vectores (embeddings).
2. Guardarlos localmente.
3. Consultarlos por similitud semántica (coseno).
4. Mostrar top resultados en la UI.

## 2. Decisión técnica principal
En lugar de usar servidor/API externa, se usó `NaturalLanguage` de Apple para embeddings locales:
1. `NLEmbedding.sentenceEmbedding(for:)` para obtener modelo de embeddings en dispositivo.
2. `vector(for:)` para convertir texto a vector `[Double]`.
3. Similaridad coseno implementada en Swift para ranking.

Esto evita dependencia de red y mantiene privacidad.

## 3. Cambios realizados en el proyecto

### 3.1 UI y flujo de búsqueda
Archivo: `TestLocalEmbeddingIos/TestLocalEmbeddingIos/ContentView.swift`

Se reemplazó la plantilla inicial de SwiftData por:
1. Campo para agregar documentos.
2. Botón para indexar documento.
3. Botón para cargar ejemplos.
4. Campo de consulta semántica.
5. Botón “Buscar top 5”.
6. Lista de resultados con score de similitud.

### 3.2 Motor local de vector search
Archivo: `TestLocalEmbeddingIos/TestLocalEmbeddingIos/ContentView.swift`

Se creó `LocalVectorSearchEngine`:
1. Inicializa embedding de español y fallback a inglés.
2. Genera vectores con `embedding?.vector(for:)`.
3. Calcula coseno entre vector query y vector documento.
4. Ordena descendentemente por similitud y retorna top K.

### 3.3 Persistencia local del índice
Archivo: `TestLocalEmbeddingIos/TestLocalEmbeddingIos/Item.swift`

`Item` cambió de `timestamp` a:
1. `text: String`
2. `vectorData: Data` (vector serializado con `JSONEncoder`/`JSONDecoder`)
3. Propiedad computada `vector: [Double]` para leer/escribir fácil.

Así los embeddings sobreviven cierre/reapertura de la app.

### 3.4 Integración con SwiftData
Archivo: `TestLocalEmbeddingIos/TestLocalEmbeddingIos/ContentView.swift`

Se usó:
1. `@Environment(\.modelContext)`
2. `@Query private var items: [Item]`
3. `modelContext.insert(...)` al indexar
4. `modelContext.delete(...)` al borrar

### 3.5 Validación
1. Diagnósticos por archivo (`XcodeRefreshCodeIssuesInFile`) sin errores.
2. Build completo (`BuildProject`) exitoso.

## 4. Documentación consultada (Apple)
Estas fueron las referencias clave para construirlo:

1. `NLEmbedding` (visión general):
https://developer.apple.com/documentation/naturallanguage/nlembedding

2. `sentenceEmbedding(for:)`:
https://developer.apple.com/documentation/naturallanguage/nlembedding/sentenceembedding(for:)

3. `vector(for:)`:
https://developer.apple.com/documentation/naturallanguage/nlembedding/vector(for:)

4. Distancias/similitud en embeddings (`NLDistanceType`, `distance`, neighbors):
https://developer.apple.com/documentation/naturallanguage/nlembedding#Finding-strings-and-their-distances-in-an-embedding

5. Guía de similitud semántica en Natural Language:
https://developer.apple.com/documentation/naturallanguage/finding-similarities-between-pieces-of-text

6. (Explorado, no usado en implementación final) `NLContextualEmbedding`:
https://developer.apple.com/documentation/naturallanguage/nlcontextualembedding

7. (Explorado para alternativas modernas) Foundation Models:
https://developer.apple.com/documentation/foundationmodels

## 5. Cómo replicarlo en otra app más completa
Checklist práctico:

1. Crear entidad persistente `Document` con `id`, `text`, `vectorData`, `createdAt`, `metadata`.
2. Crear servicio `EmbeddingService`:
   - init de `NLEmbedding.sentenceEmbedding(for:)`
   - método `embed(text:) -> [Double]?`
3. Crear `VectorIndexService`:
   - `upsert(document:)`
   - `search(query:, topK:, minScore:)`
   - coseno optimizado
4. UI:
   - ingestión masiva (archivos, notas, transcripciones)
   - búsqueda con filtros
   - detalle de resultado y score
5. Rendimiento:
   - precomputar embeddings al insertar
   - paginar búsquedas
   - considerar ANN/índice por bloques si crece mucho el corpus
6. Calidad:
   - tests unitarios de coseno/ranking
   - tests de persistencia encode/decode de vectores
   - pruebas con corpus real multilenguaje
