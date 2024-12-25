//
//  MainViewController.swift
//  Travel Book
//
//  Created by Kadir Duraklı on 30.08.2024.
//

import UIKit
import CoreData

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var locationsName : [String] = []
    var locationsID : [UUID] = []
    var chosenTitle = ""
    var chosenID : UUID?

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButonClicked))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newLocation"), object: nil)
    }
    
    @objc func getData() {
        let appData = UIApplication.shared.delegate as! AppDelegate
        let context = appData.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            
            if results.count > 0 {
                self.locationsName.removeAll(keepingCapacity: false)
                self.locationsID.removeAll(keepingCapacity: false)
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "name") as? String {
                        locationsName.append(name)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        locationsID.append(id)
                    }
                    tableView.reloadData()
                }
            }
        } catch {
            print("fail")
        }
        
        
    }
    
    @objc func addButonClicked() {
        chosenTitle = ""
        performSegue(withIdentifier: "tovc", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        locationsName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = locationsName[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = locationsName[indexPath.row]
        chosenID = locationsID[indexPath.row]
        performSegue(withIdentifier: "tovc", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tovc" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedName = chosenTitle
            destinationVC.selectedID = chosenID
        }
    }

}
