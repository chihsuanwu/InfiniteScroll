import SwiftUI

/// A SwiftUI view that enables infinite scrolling functionality.
///
/// Use the `InfiniteScroll` view to display a list of data items and load more data as the user scrolls. 
/// The view automatically handles scrolling to the top and bottom of the list and triggers the appropriate callbacks to load more data.
///
/// `InfiniteScroll` uses `LazyVStack` internally, in that it only renders the items that are currently visible on the screen.
///
/// In the following example, the `InfiniteScroll` view is used to display a list of items and load more data as the user scrolls:
/// ```swift
/// InfiniteScroll(data: items, id: \.id, onLoadPrev: loadPrev, onLoadMore: loadMore) {
///     Text("Item \($0)")
/// }
/// ```
public struct AutoInfiniteScroll<Data, ID, Content, TopProgress, BottomProgress> : View where Data : RandomAccessCollection, ID : Hashable, Content : View, TopProgress : View, BottomProgress : View {

    /// - Parameters:
    ///   - data: The data uses to create views dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - topProgress: A view builder that returns the top progress view.
    ///   - bottomProgress: A view builder that returns the bottom progress view.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder topProgress: @escaping () -> TopProgress,
        @ViewBuilder bottomProgress: @escaping () -> BottomProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        self.initialFirstVisibleItem = initialFirstVisibleItem
        self.onLoadPrev = onLoadPrev
        self.onLoadMore = onLoadMore
        self.enableLoadPrev = enableLoadPrev
        self.enableLoadMore = enableLoadMore
        self.topProgress = topProgress
        self.bottomProgress = bottomProgress
        self.content = content
    }
    
        
    /// - Parameters:
    ///   - data: The data uses to create views dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - progress: A view builder that returns the progress view for both top and bottom.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder progress: @escaping () -> TopProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where BottomProgress == TopProgress {
        self.data = data
        self.id = id
        self.initialFirstVisibleItem = initialFirstVisibleItem
        self.onLoadPrev = onLoadPrev
        self.onLoadMore = onLoadMore
        self.enableLoadPrev = enableLoadPrev
        self.enableLoadMore = enableLoadMore
        self.topProgress = progress
        self.bottomProgress = progress
        self.content = content
    }
    
    /// - Parameters:
    ///   - data: The data uses to create views dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where TopProgress == EmptyView, BottomProgress == EmptyView {
        self.data = data
        self.id = id
        self.initialFirstVisibleItem = initialFirstVisibleItem
        self.onLoadPrev = onLoadPrev
        self.onLoadMore = onLoadMore
        self.enableLoadPrev = enableLoadPrev
        self.enableLoadMore = enableLoadMore
        self.topProgress = nil
        self.bottomProgress = nil
        self.content = content
    }
    
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let initialFirstVisibleItem: ID?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    
    @ViewBuilder private let topProgress: (() -> TopProgress)?
    @ViewBuilder private let bottomProgress: (() -> BottomProgress)?
    @ViewBuilder private let content: (Data.Element) -> Content
    
    public var body: some View {
        if #available(iOS 17.0, *) {
            InfiniteScroll(
                data: data,
                id: id,
                initialFirstVisibleItem: initialFirstVisibleItem,
                onLoadPrev: onLoadPrev,
                onLoadMore: onLoadMore,
                enableLoadPrev: enableLoadPrev,
                enableLoadMore: enableLoadMore,
                topProgress: {
                    if let topProgress {
                        topProgress()
                    } else {
                        defaultProgress
                    }
                },
                bottomProgress: {
                    if let bottomProgress {
                        bottomProgress()
                    } else {
                        defaultProgress
                    }
                },
                content: content
            )
        } else {
            InfiniteScrollIOS16(
                data: data,
                id: id,
                initialFirstVisibleItem: initialFirstVisibleItem,
                onLoadPrev: onLoadPrev,
                onLoadMore: onLoadMore,
                enableLoadPrev: enableLoadPrev,
                enableLoadMore: enableLoadMore,
                topProgress: {
                    if let topProgress {
                        topProgress()
                    } else {
                        defaultProgress
                    }
                },
                bottomProgress: {
                    if let bottomProgress {
                        bottomProgress()
                    } else {
                        defaultProgress
                    }
                },
                content: content
            )
        }
    }
    
    private var defaultProgress: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
    }
}


public extension AutoInfiniteScroll where ID == Data.Element.ID, Content : View, Data.Element : Identifiable {
    
    /// - Parameters:
    ///  - data: The identifiable data uses to create views dynamically.
    ///  - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///  - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///  - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///  - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///  - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///  - topProgress: A view builder that returns the top progress view.
    ///  - bottomProgress: A view builder that returns the bottom progress view.
    ///  - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder topProgress: @escaping () -> TopProgress,
        @ViewBuilder bottomProgress: @escaping () -> BottomProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(
            data,
            id: \.id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            topProgress: topProgress,
            bottomProgress: bottomProgress,
            content: content
        )
    }
    
    /// - Parameters:
    ///  - data: The identifiable data uses to create views dynamically.
    ///  - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///  - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///  - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///  - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///  - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///  - progress: A view builder that returns the progress view for both top and bottom.
    ///  - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        progress: @escaping () -> TopProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where BottomProgress == TopProgress {
        self.init(
            data,
            id: \.id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            progress: progress,
            content: content
        )
    }
    
    /// - Parameters:
    ///  - data: The identifiable data uses to create views dynamically.
    ///  - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///  - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///  - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///  - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///  - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///  - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where TopProgress == EmptyView, BottomProgress == EmptyView {
        self.init(
            data,
            id: \.id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            content: content
        )
    }
}

