import SwiftUI

struct LandingView: View {
    @State private var selectedTab = 0
    
    init() {
        // Set the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor(named: "Primary")
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView() // HomeView will now handle its own animations
                .tabItem {
                    Image(systemName: "house.fill")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Home")
                }
                .tag(0)
            
            BookshelfView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("Bookshelf")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("Insights")
                }
                .tag(2)
        }
        .background(Color("Primary"))
        .tint(Color("Accent1"))
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}


