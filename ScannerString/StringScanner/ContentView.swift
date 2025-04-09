import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
            ResultsView(viewModel: viewModel)
        }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: ScannerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("String Scanner")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select a project folder to scan for strings")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            VStack(spacing: 15) {
                Button(action: viewModel.selectFolder) {
                    Label("Select Folder", systemImage: "folder")
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
                        Text("Start Scan")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedPath.isEmpty || viewModel.isScanning)
            }
            .padding()
            
            if viewModel.isScanning {
                ProgressView(value: viewModel.progress) {
                    Text("Scanning...")
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(minWidth: 250)
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
                    Text("No Results")
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
                            Label("Export JSON", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToCSV) {
                            Label("Export CSV", systemImage: "tablecells")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    
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
                                    Text("Localized")
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