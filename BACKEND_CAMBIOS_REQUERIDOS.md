# Backend - Cambios Necesarios para Filtrado de Categorías

## 🚨 CAMBIOS REQUERIDOS EN EL BACKEND

### 1️⃣ **Verificar que Product tenga estos campos**

```graphql
type Product {
  # ...campos existentes...
  categoryId: ID        # ⚠️ DEBE EXISTIR
  categoryName: String  # ⚠️ DEBE EXISTIR
}
```

**Prueba**: 
```graphql
query {
  products(first: 1) {
    edges {
      node {
        categoryId
        categoryName
      }
    }
  }
}
```

---

### 2️⃣ **Agregar parámetro `productCategoryId` a GetBranchesQuery**

#### Schema GraphQL:
```graphql
type Query {
  branches(
    first: Int
    after: String
    businessId: ID
    tipo: BranchTipo
    radiusKm: Float
    jwt: String
    productCategoryId: ID  # ⚠️ NUEVO - Filtra branches con productos de esta categoría
  ): BranchConnection!
}
```

#### Implementación del Resolver (Python + Qdrant):

```python
async def resolve_branches(
    self,
    info,
    first: int,
    after: Optional[str] = None,
    business_id: Optional[str] = None,
    tipo: Optional[str] = None,
    radius_km: Optional[float] = None,
    product_category_id: Optional[str] = None,  # ⚠️ NUEVO
    jwt: Optional[str] = None
):
    # Tu lógica existente de búsqueda de branches...
    branches = await search_branches(
        tipo=tipo,
        radius_km=radius_km,
        # ...otros filtros...
    )
    
    # ⚠️ NUEVO: Filtrar por productos con categoría específica
    if product_category_id:
        # Buscar productos que tienen esta categoría
        products = await search_products_by_category(
            category_id=product_category_id
        )
        
        # Obtener IDs únicos de branches que tienen esos productos
        branch_ids_with_category = set(
            product.branch_id for product in products
        )
        
        # Filtrar branches para incluir solo los que tienen productos de esta categoría
        branches = [
            branch for branch in branches 
            if branch.id in branch_ids_with_category
        ]
    
    # Aplicar paginación y retornar
    return paginate_branches(branches, first, after)
```

#### Función auxiliar de búsqueda de productos por categoría:

```python
async def search_products_by_category(category_id: str) -> List[Product]:
    """
    Busca productos que tienen la categoría especificada.
    Ajusta según tu implementación (Qdrant, MongoDB, etc.)
    """
    # Ejemplo con Qdrant
    products = await qdrant_client.search(
        collection_name="products",
        query_filter={
            "must": [
                {"key": "categoryId", "match": {"value": category_id}}
            ]
        },
        limit=1000  # Ajustar según necesidades
    )
    return products
```

---

### 3️⃣ **Prueba el nuevo filtrado**

```graphql
query TestBranchCategoryFilter {
  branches(
    first: 10
    tipo: RESTAURANTE
    productCategoryId: "id-de-categoria-comida"  # ⚠️ Usa un ID real
  ) {
    edges {
      node {
        id
        name
      }
    }
  }
}
```

Deberías ver solo branches (restaurantes) que tienen productos con esa categoría.

---

## 📝 Resumen

| Cambio | Estado | Dificultad |
|--------|--------|-----------|
| Verificar `categoryId` y `categoryName` en Product | ⚠️ Pendiente | Fácil |
| Agregar parámetro `productCategoryId` en schema | ⚠️ Pendiente | Fácil |
| Implementar filtrado en resolver de branches | ⚠️ Pendiente | Media |

---

## ✅ Ya está listo en el Frontend

El iOS app ya:
- ✅ Pasa `categoryId` en queries de productos
- ✅ Espera `categoryId` y `categoryName` en respuestas
- ✅ Filtra localmente como respaldo
- ✅ Limita "Populares cerca de ti" a 3 km

Solo falta que el backend implemente el filtrado de branches por categoría de producto.
