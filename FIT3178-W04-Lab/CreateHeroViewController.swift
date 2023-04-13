//
//  DatabaseProtocol.swift
//  FIT3178-W04-Lab
//
//  Created by Jason Haasz on 4/1/2023.
//

import UIKit

class CreateHeroViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var abilitiesTextField: UITextField!
    @IBOutlet weak var universeSegmentedControl: UISegmentedControl!
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        // Do any additional setup after loading the view.
    }
    
    @IBAction func createHero(_ sender: Any) {
        guard let name = nameTextField.text, let abilities = abilitiesTextField.text, let universe = Universe(rawValue: Int(universeSegmentedControl.selectedSegmentIndex)) else {
            return
        }

        if name.isEmpty || abilities.isEmpty {
            var errorMsg = "Please ensure all fields are filled:\n"
            if name.isEmpty {
                errorMsg += "- Must provide a name\n"
            }
            if abilities.isEmpty {
                errorMsg += "- Must provide abilities"
            }
            displayMessage(title: "Not all fields filled", message: errorMsg)
            return
        }

        let _ = databaseController?.addSuperhero(name: name, abilities: abilities, universe: universe)

        navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
