//
//  MainAppFileManager.swift
//  Common
//
//  Created by jeezs on 15/02/2025.
//

import Foundation
import UIKit
import Combine  // Ajout de cet import

@MainActor
public class MainAppFileManager: ObservableObject {
    public static let shared = MainAppFileManager()
    
    @Published public var isInitialized = false
    
    private init() {}
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getSharedContainer() -> URL? {
        let groupID = "group.atome.one"
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            print("📂 Utilisation du conteneur de groupe: \(containerURL.path)")
            return containerURL
        }
        return nil
    }
    
    private func makeVisible(_ path: String) {
        do {
            // Définir les permissions
            try FileManager.default.setAttributes([
                .posixPermissions: 0o777  // Permissions complètes pour test
            ], ofItemAtPath: path)
            
            // Configurer les attributs de l'URL
            var url = URL(fileURLWithPath: path)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try url.setResourceValues(resourceValues)
            
            // Créer un fichier .nomedia pour forcer la visibilité
            let nomediaPath = (path as NSString).appendingPathComponent(".nomedia")
            FileManager.default.createFile(atPath: nomediaPath, contents: nil)
            
            print("✅ Visibilité configurée pour: \(path)")
        } catch {
            print("⚠️ Erreur lors de la configuration de la visibilité: \(error)")
        }
    }
    
    public func initializeFileStructure() {
        print("=== INITIALISATION FICHIERS APP PRINCIPALE ===")
        
        // Utiliser le dossier Documents pour la visibilité
        let documentsURL = getDocumentsDirectory()
        let atomeFilesURL = documentsURL.appendingPathComponent("AtomeFiles", isDirectory: true)
        
        print("📂 Chemin AtomeFiles: \(atomeFilesURL.path)")
        
        do {
            let fileManager = FileManager.default
            
            // Créer le dossier s'il n'existe pas
            if !fileManager.fileExists(atPath: atomeFilesURL.path) {
                try fileManager.createDirectory(at: atomeFilesURL,
                                             withIntermediateDirectories: true,
                                             attributes: [FileAttributeKey.posixPermissions: 0o777])
                print("📁 Dossier AtomeFiles créé")
            }
            
            makeVisible(atomeFilesURL.path)
            
            // Gérer le conteneur partagé
            if let sharedContainer = getSharedContainer() {
                let sharedAtomeFilesURL = sharedContainer.appendingPathComponent("AtomeFiles", isDirectory: true)
                if !fileManager.fileExists(atPath: sharedAtomeFilesURL.path) {
                    try fileManager.createDirectory(at: sharedAtomeFilesURL,
                                                 withIntermediateDirectories: true,
                                                 attributes: [FileAttributeKey.posixPermissions: 0o777])
                    makeVisible(sharedAtomeFilesURL.path)
                }
                
                // Créer un fichier de test dans le dossier Documents
                let welcomeFileURL = atomeFilesURL.appendingPathComponent("welcome.txt")
                let welcomeContent = """
                Bienvenue dans Atome!
                Dossier créé le \(Date())
                Ceci est un fichier de test visible dans Fichiers.
                """
                
                if !fileManager.fileExists(atPath: welcomeFileURL.path) {
                    try welcomeContent.write(to: welcomeFileURL, atomically: true, encoding: .utf8)
                    makeVisible(welcomeFileURL.path)
                    print("📄 Fichier welcome.txt créé")
                }
            }
            
            // Vérifier le contenu
            if let contents = try? fileManager.contentsOfDirectory(at: atomeFilesURL, includingPropertiesForKeys: nil) {
                print("📝 Contenu du dossier AtomeFiles:")
                contents.forEach { print("   - \($0.lastPathComponent)") }
            }
            
            // Forcer un rafraîchissement
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                             to: nil,
                                             from: nil,
                                             for: nil)
            }
            
            isInitialized = true
            print("✅ Initialisation réussie")
            
        } catch {
            print("❌ Erreur lors de l'initialisation:")
            let nsError = error as NSError
            print("Domain: \(nsError.domain)")
            print("Code: \(nsError.code)")
            print("Description: \(nsError.localizedDescription)")
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("Erreur sous-jacente: \(underlyingError)")
            }
        }
    }
}
