import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
            ResultsView(viewModel: viewModel)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: ScannerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("String Scanner".localized)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select a project folder to scan for strings".localized)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            VStack(spacing: 15) {
                Button(action: viewModel.selectFolder) {
                    Label("Select Folder".localized, systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isScanning)
                
                Text(viewModel.selectedPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal)
                
                Button(action: viewModel.startScan) {
                    if viewModel.isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    } else {
                        Text("Start Scan".localized)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedPath.isEmpty || viewModel.isScanning)
            }
            .padding()
            
            if viewModel.isScanning {
                ProgressView(value: viewModel.progress) {
                    Text("Scanning...".localized)
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(minWidth: 250)
        .id(viewModel.languageChanged)
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            viewModel.languageChanged.toggle()
        }
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    
    var body: some View {
        VStack {
            if viewModel.results.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Results".localized)
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Select a folder and start scanning to find strings")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: viewModel.exportToJSON) {
                            Label("Export JSON".localized, systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToCSV) {
                            Label("Export CSV".localized, systemImage: "tablecells")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToLocalizationFiles) {
                            Label("Export Strings".localized, systemImage: "text.quote")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToXCStrings) {
                            Label("Export XCStrings".localized, systemImage: "globe")
                        }
                        .buttonStyle(.bordered)
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    List(viewModel.results, id: \.self) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.content)
                                .font(.body)
                            
                            HStack {
                                Text(result.file)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Line \(result.line)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if result.isLocalized {
                                    Text("Localized".localized)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(minWidth: 500)
    }
}

#Preview {
    ContentView()
}
