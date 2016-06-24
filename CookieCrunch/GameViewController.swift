//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Andre Morais on 6/21/16.
//  Copyright (c) 2016 Andre Morais. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    var scene: GameScene!
    var level: Level!
    
    var movesLeft = 0
    var score = 0
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var gameOverPanel: UIImageView!
    
    @IBOutlet weak var shuffleButton: UIButton!
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    var currentLevelNum = 1
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3") else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOfURL: url)
            player.numberOfLoops = -1
            return player
        } catch {
            return nil
        }
    }()
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup view with level 1
        setupLevel(currentLevelNum)
        
        // Start the background music.
        backgroundMusic?.play()
    }
    
    func setupLevel(levelNum: Int) {
        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        // Setup the level.
        level = Level(filename: "Level_\(levelNum)")
        scene.level = level
        
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        gameOverPanel.hidden = true
        shuffleButton.hidden = true
        
        // Present the scene.
        skView.presentScene(scene)
        
        // Start the game.
        beginGame()
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        shuffleButton.hidden = true
//        gameOverPanel.hidden = true
//        
//        // Configure the view.
//        let skView = view as! SKView
//        skView.multipleTouchEnabled = false
//        
//        // Create and configure the scene.
//        scene = GameScene(size: skView.bounds.size)
//        scene.scaleMode = .AspectFill
//        
//        // Present the scene.
//        skView.presentScene(scene)
//        
//        level = Level(filename: "Level_1")
//        scene.level = level
//
//        scene.addTiles()
//        
//        backgroundMusic?.play()
//
//        beginGame()
//        
//        scene.swipeHandler = handleSwipe
//        
//    }
    
    func beginGame() {
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        level.resetComboMultiplier()

        shuffle()
        scene.animateBeginGame() {
            self.shuffleButton.hidden = false
        }
    }
    
    func shuffle() {
        scene.removeAllCookieSprites()

        let newCookies = level.shuffle()
        scene.addSpritesForCookies(newCookies)
    }
    
    func handleSwipe(swap: Swap) {
        view.userInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            
            scene.animateSwap(swap, completion: handleMatches)
//            scene.animateSwap(swap) {
//                self.view.userInteractionEnabled = true
//            }
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.userInteractionEnabled = true
            }
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        
        scene.animateMatchedCookies(chains) {
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns) {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns) {
                    self.handleMatches()
                }
            }
        }
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
        decrementMoves()
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }
    
    func decrementMoves() {
        movesLeft -= 1
        updateLabels()
        
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum+1 : 1
            showGameOver()
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }
    
    func showGameOver() {
        shuffleButton.hidden = true
        gameOverPanel.hidden = false
        scene.userInteractionEnabled = false
        
        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    
    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.hidden = true
        scene.userInteractionEnabled = true
        
        setupLevel(currentLevelNum)
    }
    
    @IBAction func shuffleButtonPressed(_: AnyObject) {
        shuffle()
        decrementMoves()
    }
}














