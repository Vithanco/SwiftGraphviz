# SwiftGraphviz Migration Guide

## v0.3.0 → v0.3.1

### Summary

Removed the `GraphvizGraph` builder class and associated app-specific types. Consumers now call Graphviz C functions directly (`agopen`, `agnode`, `agedge`, `agset`, `gvLayout`, etc.) while still benefiting from type-safe enums, layout structs, pointer extensions, and CoreGraphics bridging.

### Breaking Changes

#### Removed: `GraphvizGraph` class

The builder class that wrapped all C calls has been removed. Replace with direct C function calls using the now-public `gblGVContext`.

**Before:**
```swift
let config = GVLayoutConfig(name: "my", layoutEngine: .dot, ...)
let graph = GraphvizGraph(name: "G", type: .nonStrictDirected, layouter: config)
let n1 = graph.newNode(name: "a", label: "A")
let n2 = graph.newNode(name: "b", label: "B")
let edge = graph.newEdge(from: n1, to: n2, name: "e1", dir: .forward)
graph.setBaseValue(param: .graph(.rankdir), value: "LR")
graph.setNodeValue(n1, .shape, "box")
graph.layout()
let rect = graph.getGraphRect()
```

**After:**
```swift
let g = agopen("G", Agdesc_t(directed: 1, strict: 0, no_loop: 0, maingraph: 1, no_write: 0, has_attrs: 0, has_cmpnd: 0), nil)!
// Register default attributes (required before setting values on individual elements)
g.setDefault(.graph(.rankdir), value: "LR")
g.setDefault(.node(.label))
g.setDefault(.node(.shape))
g.setDefault(.edge(.dir))

let n1 = agnode(g, "a", 1)!
n1.set(.label, "A")
let n2 = agnode(g, "b", 1)!
n2.set(.label, "B")
let edge = agedge(g, n1, n2, "e1", 1)!
edge.set(.dir, GVEdgeParamDir.forward.rawValue)
n1.set(.shape, "box")

gvLayout(gblGVContext, g, GVLayoutEngine.dot.graphvizName)
let rect = CGRect(box: gd_bb(g))

// Cleanup
gvFreeLayout(gblGVContext, g)
agclose(g)
```

> **Important**: You must call `agattr()` to set a base/default value for any attribute before using `agset()` on individual elements. Without this, `agset()` silently has no effect. This is a Graphviz C API requirement that `GraphvizGraph` previously handled in DEBUG mode with assertions.

#### Removed: `GraphBuilder` protocol

The `GraphBuilder` protocol and its default `setBaseValues` extension have been removed. Call C functions directly.

#### Removed: `GraphBuilderBias`

Move this to your app if you need edge-direction reversal logic.

#### Removed: `GVLayoutConfig`

Replace with direct `gvLayout()` calls:
```swift
gvLayout(gblGVContext, g, GVLayoutEngine.dot.graphvizName)
```

#### Removed: `GVGraphType` enum

Use `Agdesc_t` directly. Common configurations:

```swift
// Non-strict directed (most common)
Agdesc_t(directed: 1, strict: 0, no_loop: 0, maingraph: 1, no_write: 0, has_attrs: 0, has_cmpnd: 0)

// Strict directed (one edge per node pair)
Agdesc_t(directed: 1, strict: 1, no_loop: 0, maingraph: 1, no_write: 0, has_attrs: 0, has_cmpnd: 0)

// Non-strict undirected
Agdesc_t(directed: 0, strict: 0, no_loop: 0, maingraph: 1, no_write: 0, has_attrs: 0, has_cmpnd: 0)

// Strict undirected
Agdesc_t(directed: 0, strict: 1, no_loop: 0, maingraph: 1, no_write: 0, has_attrs: 0, has_cmpnd: 0)
```

> **Bug fix**: The old `GVGraphType.strictNonDirected` incorrectly set `directed: 1`. The correct value is `directed: 0` as shown above.

#### Removed: App-specific enums

The following enums were removed because they encode app-specific (Vithanco) logic. Copy them to your app if needed:

- `GVModelDirection` — direction/port mapping logic
- `GraphBias` — fletchingSide/pointySide concept
- `GVClusterLabelPos` — cluster label positioning
- `GVNodeShape` — only had box/circle (Graphviz supports ~50 shapes)

#### Removed: Utility files

- `Logging.swift` — replace with your own logger
- `Double+KKExtensions.swift`, `Set+KKExtentions.swift`, `CGRect+KKExtensions.swift` — trivial/dead code

#### Removed: Miscellaneous

- `verboseGraphviz()` — call `gvParseArgs` directly if needed
- `stdFontName` / `stdFontNameBold` — define in your app
- `CHAR` / `CHAR_ARRAY` type aliases — use `withCString` pattern instead
- `GVPixel` type alias — replaced by type-safe `GVPoints`/`GVInches` (see below)

### Changed: `GVPixel` replaced with type-safe `GVPoints` / `GVInches`

Graphviz uses inches internally for node dimensions, but screen coordinates are in points (72 points = 1 inch). The old `GVPixel = CGFloat` alias provided no safety. Now there are two wrapper structs:

```swift
public struct GVPoints {
    public let value: CGFloat
    public init(_ value: CGFloat)
    public var asInches: GVInches
}

public struct GVInches {
    public let value: CGFloat
    public init(_ value: CGFloat)
    public var asPoints: GVPoints
}
```

**Migration:**
- `GVNode.width` and `GVNode.height` now return `GVPoints` instead of `CGFloat`. Access `.value` to get the raw `CGFloat`.
- `GVNode.widthInches` and `GVNode.heightInches` are new properties returning `GVInches`.
- `pixelToInchParameter()` now accepts `GVPoints` instead of `CGFloat`.
- `GVNode.size` and `GVNode.rect` still return `CGSize` and `CGRect` (unchanged).

### Changed: `gblGVContext` is now public

The global Graphviz context is now publicly accessible for direct `gvLayout`/`gvFreeLayout`/`gvRender` calls.

### Changed: `cString()` replaced with safe patterns

Internal C string conversion now uses Swift's `withCString` closures instead of the unsafe `UnsafeMutablePointer<Int8>(mutating:)` pattern.

### Changed: Removed redundant `Hashable` conformances

Custom `Hashable` conformances for `CGRect`, `CGSize`, and `CGPoint` were removed since CoreGraphics provides these natively on macOS 15+ / iOS 18+ (matching our deployment targets).

### Changed: Enums simplified

All kept enums had `@objc`, `readableName`, and `readableNames` removed. If your app used these, move them to your app code.

### Unchanged (still available)

- **Parameter enums**: `GVEdgeParameters`, `GVGraphParameters`, `GVNodeParameters`, `GVParameter`, `GVParams` — use `.rawValue` for attribute name strings
- **Value enums**: `GVEdgeParamDir`, `GVEdgeStyle`, `GVRank`, `GVParamValueOverlap`, `GVEdgeEnding`
- **`GVLayoutEngine`** — simplified (removed `@objc` and `readableName`)
- **Type aliases**: `GVNode`, `GVEdge`, `GVGraph`, `GVCluster`, `GVSplines`, `GVBezier`, `GVGlobalContextPointer`
- **Pointer extensions**: `GVNode.pos/.rect/.size`, `GVEdge.getPath()/.labelPos/.arrowHead`, `GVGraph.asString/.saveTo()/.unflatten()`
- **Layout structs**: `EdgeLayout`, `NodeLayout`, `ClusterLayout`
- **Constants**: `pointsPerInch`, `pixelToInchParameter()`
- **CoreGraphics bridging**: `CGPoint(gvPoint:)`, `CGRect(box:)`, `CGRect(midPoint:size:)`
- **Geometry utilities**: CGVector extensions, CGPoint extensions, NSBezierPath arrow/circle/diamond construction
- **Lifecycle**: `finishGraphviz()`
