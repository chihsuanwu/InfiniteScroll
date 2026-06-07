import SwiftUI

/// A SwiftUI view that enables infinite scrolling functionality.
///
/// Use the `InfiniteScroll` view to display a list of data items and load more data as the user scrolls.
/// The view automatically handles scrolling to the top and bottom of the list and triggers the appropriate callbacks to load more data.
///
/// `InfiniteScroll` uses `LazyVStack` internally, in that it only renders the items that are currently visible on the screen.
public struct AutoInfiniteScroll<Data, ID, Content, TopProgress, BottomProgress>: View
where Data: RandomAccessCollection,
      ID: Hashable,
      Content: View,
      TopProgress: View,
      BottomProgress: View
{
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let initialFirstVisibleItem: ID?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    let loadingBinding: Binding<Bool>?
    let scrollPositionBinding: Binding<ID?>?
    let scrollToIDRequestBinding: Binding<ID?>?
    let scrollToTopIDRequestBinding: Binding<ID?>?
    let preventLoadPrevBinding: Binding<Bool>?
    let contentBottomInset: CGFloat
    let contentTopInset: CGFloat
    let scrollPositionAnchor: UnitPoint

    @ViewBuilder private let topProgress: (() -> TopProgress)?
    @ViewBuilder private let bottomProgress: (() -> BottomProgress)?
    @ViewBuilder private let content: (Data.Element) -> Content

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        loading: Binding<Bool>? = nil,
        scrollPosition: Binding<ID?>? = nil,
        scrollToIDRequest: Binding<ID?>? = nil,
        scrollToTopIDRequest: Binding<ID?>? = nil,
        preventLoadPrev: Binding<Bool>? = nil,
        contentBottomInset: CGFloat = 0,
        contentTopInset: CGFloat = 0,
        scrollPositionAnchor: UnitPoint = .bottom,
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
        self.loadingBinding = loading
        self.scrollPositionBinding = scrollPosition
        self.scrollToIDRequestBinding = scrollToIDRequest
        self.scrollToTopIDRequestBinding = scrollToTopIDRequest
        self.preventLoadPrevBinding = preventLoadPrev
        self.contentBottomInset = contentBottomInset
        self.contentTopInset = contentTopInset
        self.scrollPositionAnchor = scrollPositionAnchor
        self.topProgress = topProgress
        self.bottomProgress = bottomProgress
        self.content = content
    }

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        loading: Binding<Bool>? = nil,
        scrollPosition: Binding<ID?>? = nil,
        scrollToIDRequest: Binding<ID?>? = nil,
        scrollToTopIDRequest: Binding<ID?>? = nil,
        preventLoadPrev: Binding<Bool>? = nil,
        contentBottomInset: CGFloat = 0,
        contentTopInset: CGFloat = 0,
        scrollPositionAnchor: UnitPoint = .bottom,
        @ViewBuilder progress: @escaping () -> TopProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where BottomProgress == TopProgress {
        self.init(
            data,
            id: id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            loading: loading,
            scrollPosition: scrollPosition,
            scrollToIDRequest: scrollToIDRequest,
            scrollToTopIDRequest: scrollToTopIDRequest,
            preventLoadPrev: preventLoadPrev,
            contentBottomInset: contentBottomInset,
            contentTopInset: contentTopInset,
            scrollPositionAnchor: scrollPositionAnchor,
            topProgress: progress,
            bottomProgress: progress,
            content: content
        )
    }

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        loading: Binding<Bool>? = nil,
        scrollPosition: Binding<ID?>? = nil,
        scrollToIDRequest: Binding<ID?>? = nil,
        scrollToTopIDRequest: Binding<ID?>? = nil,
        preventLoadPrev: Binding<Bool>? = nil,
        contentBottomInset: CGFloat = 0,
        contentTopInset: CGFloat = 0,
        scrollPositionAnchor: UnitPoint = .bottom,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where TopProgress == EmptyView, BottomProgress == EmptyView {
        self.data = data
        self.id = id
        self.initialFirstVisibleItem = initialFirstVisibleItem
        self.onLoadPrev = onLoadPrev
        self.onLoadMore = onLoadMore
        self.enableLoadPrev = enableLoadPrev
        self.enableLoadMore = enableLoadMore
        self.loadingBinding = loading
        self.scrollPositionBinding = scrollPosition
        self.scrollToIDRequestBinding = scrollToIDRequest
        self.scrollToTopIDRequestBinding = scrollToTopIDRequest
        self.preventLoadPrevBinding = preventLoadPrev
        self.contentBottomInset = contentBottomInset
        self.contentTopInset = contentTopInset
        self.scrollPositionAnchor = scrollPositionAnchor
        self.topProgress = nil
        self.bottomProgress = nil
        self.content = content
    }

    public var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            InfiniteScroll(
                data: data,
                id: id,
                initialFirstVisibleItem: initialFirstVisibleItem,
                onLoadPrev: onLoadPrev,
                onLoadMore: onLoadMore,
                enableLoadPrev: enableLoadPrev,
                enableLoadMore: enableLoadMore,
                loadingBinding: loadingBinding,
                scrollPositionBinding: scrollPositionBinding,
                scrollToIDRequestBinding: scrollToIDRequestBinding,
                scrollToTopIDRequestBinding: scrollToTopIDRequestBinding,
                preventLoadPrevBinding: preventLoadPrevBinding,
                contentBottomInset: contentBottomInset,
                contentTopInset: contentTopInset,
                scrollPositionAnchor: scrollPositionAnchor,
                topProgress: {
                    if let topProgress {
                        topProgress()
                    } else {
                        EmptyView()
                    }
                },
                bottomProgress: {
                    if let bottomProgress {
                        bottomProgress()
                    } else {
                        EmptyView()
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

public extension AutoInfiniteScroll where ID == Data.Element.ID, Content: View, Data.Element: Identifiable {
    init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        loading: Binding<Bool>? = nil,
        scrollPosition: Binding<ID?>? = nil,
        scrollToIDRequest: Binding<ID?>? = nil,
        scrollToTopIDRequest: Binding<ID?>? = nil,
        preventLoadPrev: Binding<Bool>? = nil,
        contentBottomInset: CGFloat = 0,
        contentTopInset: CGFloat = 0,
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
            loading: loading,
            scrollPosition: scrollPosition,
            scrollToIDRequest: scrollToIDRequest,
            scrollToTopIDRequest: scrollToTopIDRequest,
            preventLoadPrev: preventLoadPrev,
            contentBottomInset: contentBottomInset,
            contentTopInset: contentTopInset,
            topProgress: topProgress,
            bottomProgress: bottomProgress,
            content: content
        )
    }

    init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        loading: Binding<Bool>? = nil,
        scrollPosition: Binding<ID?>? = nil,
        scrollToIDRequest: Binding<ID?>? = nil,
        scrollToTopIDRequest: Binding<ID?>? = nil,
        preventLoadPrev: Binding<Bool>? = nil,
        contentBottomInset: CGFloat = 0,
        contentTopInset: CGFloat = 0,
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
            loading: loading,
            scrollPosition: scrollPosition,
            scrollToIDRequest: scrollToIDRequest,
            scrollToTopIDRequest: scrollToTopIDRequest,
            preventLoadPrev: preventLoadPrev,
            contentBottomInset: contentBottomInset,
            contentTopInset: contentTopInset,
            progress: progress,
            content: content
        )
    }

    init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        loading: Binding<Bool>? = nil,
        scrollPosition: Binding<ID?>? = nil,
        scrollToIDRequest: Binding<ID?>? = nil,
        scrollToTopIDRequest: Binding<ID?>? = nil,
        preventLoadPrev: Binding<Bool>? = nil,
        contentBottomInset: CGFloat = 0,
        contentTopInset: CGFloat = 0,
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
            loading: loading,
            scrollPosition: scrollPosition,
            scrollToIDRequest: scrollToIDRequest,
            scrollToTopIDRequest: scrollToTopIDRequest,
            preventLoadPrev: preventLoadPrev,
            contentBottomInset: contentBottomInset,
            contentTopInset: contentTopInset,
            content: content
        )
    }
}
