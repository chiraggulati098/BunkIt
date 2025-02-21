//
//  ContentView.swift
//  BunkIt
//
//  Created by Chirag Gulati on 12/02/25.
//

import SwiftUI

struct Subject: Codable, Identifiable {
    var id = UUID()
    var name: String
    var attended: Int
    var total: Int
    
    var attendancePercentage: Double {
        total == 0 ? 0 : (Double(attended) / Double(total)) * 100
    }
    
    var attendanceStatus: String {
        let threshold = 75.0
        if attendancePercentage >= threshold {
            let bunkable = Int((Double(attended) / 3) - Double(total - attended))
            return "You can bunk \(bunkable) class\(bunkable == 1 ? "" : "es")"
        } else {
            let needed = Int(((total - attended) * 3) - attended)
            return "Attend \(needed) more class\(needed == 1 ? "" : "es") to reach 75%"
        }
    }
    
    var attendanceColor: Color {
        return attendancePercentage >= 75 ? .green : .red
    }
}

struct ContentView: View {
    @State private var subjects: [Subject] = [] {
        didSet {
            saveSubjects()
        }
    }
    @State private var showAlert = false
    @State private var newSubjectName: String = ""
    @State private var attendedClasses: String = ""
    @State private var missedClasses: String = ""
    
    @State private var showActionSheet = false
    @State private var selectedSubjectIndex: Int? = nil
    @State private var showDeleteAlert = false
    @State private var showEditPopup = false
    
    var body: some View {
        NavigationView {
            VStack {
                if subjects.isEmpty {
                    Text("No subjects added yet")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    SubjectsListView(
                        subjects: $subjects,
                        selectedSubjectIndex: $selectedSubjectIndex,
                        showActionSheet: $showActionSheet,
                        saveSubjects: saveSubjects
                    )
                }
            }
            .navigationTitle("BunkIt")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAlert = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear() {
                loadSubjects()
            }
            .alert("Add New Subject", isPresented: $showAlert) {
                VStack {
                    TextField("Subject Name", text: $newSubjectName)
                    TextField("Classes Attended", text: $attendedClasses).keyboardType(.numberPad)
                    TextField("Classes Missed", text: $missedClasses).keyboardType(.numberPad)
                }
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    addSubject()
                }
            }
            .confirmationDialog("Actions", isPresented: $showActionSheet, titleVisibility: .visible) {
                Button("Edit Subject") {
                    if let index = selectedSubjectIndex {
                        newSubjectName = subjects[index].name
                        attendedClasses = String(subjects[index].attended)
                        missedClasses = String(subjects[index].total - subjects[index].attended)
                        showEditPopup = true
                    }
                }
                
                Button("Delete Subject", role: .destructive) {
                    showDeleteAlert = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Are you sure you want to delete this subject?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let index = selectedSubjectIndex {
                        subjects.remove(at: index)
                    }
                }
            }
            .alert("Edit Subject", isPresented: $showEditPopup) {
                VStack {
                    TextField("Subject Name", text: $newSubjectName)
                    TextField("Classes Attended", text: $attendedClasses).keyboardType(.numberPad)
                    TextField("Classes Missed", text: $missedClasses).keyboardType(.numberPad)
                }
                Button("Cancel", role: .cancel) { }
                Button("Update") {
                    updateSubject()
                }
            }
        }
    }
    
    func addSubject() {
        let trimmedName = newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let attended = Int(attendedClasses), let missed = Int(missedClasses), !trimmedName.isEmpty {
                let total = attended + missed
                let newSubject = Subject(name: trimmedName, attended: attended, total: total)
                subjects.append(newSubject)
        }
        resetFields()
    }
    
    func updateSubject() {
        if let index = selectedSubjectIndex,
           let attended = Int(attendedClasses),
           let missed = Int(missedClasses),
           !newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            let total = attended + missed
            subjects[index].name = newSubjectName
            subjects[index].attended = attended
            subjects[index].total = total
        }
    }
    
    func resetFields() {
        newSubjectName = ""
        attendedClasses = ""
        missedClasses = ""
    }
    
    func saveSubjects() {
        if let encoded = try? JSONEncoder().encode(subjects) {
            UserDefaults.standard.set(encoded, forKey: "subjects")
        }
    }
    
    func loadSubjects() {
        if let savedData = UserDefaults.standard.data(forKey: "subjects"),
           let decodedSubjects = try? JSONDecoder().decode([Subject].self, from: savedData) {
            subjects = decodedSubjects
        }
    }
}

struct SubjectsListView: View {
    @Binding var subjects: [Subject]
    @Binding var selectedSubjectIndex: Int?
    @Binding var showActionSheet: Bool
    var saveSubjects: () -> Void
    
    var body: some View {
        List {
            ForEach(subjects.indices, id: \.self) { index in
                SubjectRow(
                    subject: $subjects[index],
                    onLongPress: {
                        selectedSubjectIndex = index
                        showActionSheet = true
                    },
                    saveSubjects: saveSubjects
                )}
            
            
            Section {
                Text("Created with ❤️ by Chirag")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
            }
        }
    }
}

struct SubjectRow: View {
    @Binding var subject: Subject
    var onLongPress: () -> Void
    var saveSubjects: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(subject.name).font(.headline)
                
                Text("Attended: \(subject.attended), Total: \(subject.total)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(subject.attendancePercentage, specifier: "%.1f")% attendance")
                    .font(.subheadline)
                
                Text(subject.attendanceStatus)
                    .font(.footnote)
                    .foregroundColor(subject.attendanceColor)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: {
                    subject.attended += 1
                    subject.total += 1
                    saveSubjects()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    subject.total += 1
                    saveSubjects()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onLongPressGesture {
            onLongPress()
        }
    }
}

#Preview {
    ContentView()
}
