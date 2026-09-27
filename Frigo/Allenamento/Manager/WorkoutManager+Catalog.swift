import Foundation

extension WorkoutManager {
  func setupExerciseDatabase() {
    exerciseDatabase = [
      ExerciseModel(
        name: "Panca Piana con Bilanciere",
        description: "Esercizio multiarticolare per la costruzione del gran pettorale.",
        primaryMuscle: .chest,
        equipmentRequirement: "Panca e Bilanciere",
        imageName: "bench_press_anim"
      ),
      ExerciseModel(
        name: "Squat",
        description: "Il re della parte inferiore. Sviluppa quadricipiti e glutei potenti.",
        primaryMuscle: .legs,
        equipmentRequirement: "Rack e Bilanciere",
        imageName: "squat_anim"
      ),
      ExerciseModel(
        name: "Trazioni alla Sbarra",
        description: "Esercizio base a corpo libero per l'ipertrofia del gran dorsale.",
        primaryMuscle: .back,
        equipmentRequirement: "Sbarra per Trazioni",
        imageName: "pull_ups_anim"
      ),
      ExerciseModel(
        name: "Military Press",
        description: "Spinte verticali con bilanciere per rinforzare i deltoidi.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Bilanciere",
        imageName: "military_press_anim"
      ),
      ExerciseModel(
        name: "Curl Bicipiti con Manubri",
        description: "Classico esercizio di isolamento delle braccia.",
        primaryMuscle: .arms,
        equipmentRequirement: "Manubri",
        imageName: "bicep_curl_anim"
      ),
            ExerciseModel(
        name: "Spinte con manubri su panca piana",
        description: "Esercizio per il petto con manubri.",
        primaryMuscle: .chest,
        equipmentRequirement: "Manubri e Panca",
        imageName: "dumbbell_bench_press_anim"
      ),
      ExerciseModel(
        name: "Chest Press macchinario",
        description: "Esercizio al macchinario per il grande pettorale.",
        primaryMuscle: .chest,
        equipmentRequirement: "Macchinario",
        imageName: "chest_press_anim"
      ),
      ExerciseModel(
        name: "Lento avanti con manubri da seduti",
        description: "Schiena ben appoggiata allo schienale. Per le spalle.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Manubri e Panca",
        imageName: "seated_press_anim"
      ),
      ExerciseModel(
        name: "Alzate laterali con manubri",
        description: "Esercizio di isolamento per i deltoidi laterali.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Manubri",
        imageName: "lateral_raises_anim"
      ),
      ExerciseModel(
        name: "Lat machine avanti",
        description: "Trazione verticale per il dorso.",
        primaryMuscle: .back,
        equipmentRequirement: "Lat Machine",
        imageName: "lat_pulldown_anim"
      ),
      ExerciseModel(
        name: "Pushdown ai cavi",
        description: "Esercizio di isolamento per i tricipiti.",
        primaryMuscle: .arms,
        equipmentRequirement: "Cavi",
        imageName: "tricep_pushdown_anim"
      ),
      ExerciseModel(
        name: "Leg Press a 45 gradi",
        description: "Non staccare MAI il sedere e la parte bassa della schiena dallo schienale.",
        primaryMuscle: .legs,
        equipmentRequirement: "Leg Press",
        imageName: "leg_press_anim"
      ),
      ExerciseModel(
        name: "Leg Extension",
        description: "Esercizio di isolamento per i quadricipiti.",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "leg_extension_anim"
      ),
      ExerciseModel(
        name: "Leg Curl da seduto",
        description: "Isolamento per i femorali da seduto.",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "seated_leg_curl_anim"
      ),
      ExerciseModel(
        name: "Calf alla pressa",
        description: "Esercizio per i polpacci alla pressa.",
        primaryMuscle: .legs,
        equipmentRequirement: "Leg Press",
        imageName: "calf_press_anim"
      ),
      ExerciseModel(
        name: "Plank",
        description: "Esercizio statico per il core. Fermati non appena perdi la postura corretta.",
        primaryMuscle: .core,
        equipmentRequirement: "Corpo libero",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Bird-Dog",
        description: "Esercizio per stabilità L4-L5.",
        primaryMuscle: .core,
        equipmentRequirement: "Corpo libero",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Iperestensioni su panca",
        description: "A corpo libero, con esecuzione lenta e controllata.",
        primaryMuscle: .core,
        equipmentRequirement: "Panca per lombari",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Rematore al macchinario con appoggio",
        description: "Tieni il petto saldamente in appoggio per proteggere la bassa schiena.",
        primaryMuscle: .back,
        equipmentRequirement: "Macchinario",
        imageName: "lat_pulldown_anim"
      ),
      ExerciseModel(
        name: "Lat machine con presa inversa",
        description: "Variante per dorso e bicipiti.",
        primaryMuscle: .back,
        equipmentRequirement: "Lat Machine",
        imageName: "lat_pulldown_anim"
      ),
      ExerciseModel(
        name: "Pectoral Machine",
        description: "Esercizio di isolamento per il petto (croci al macchinario).",
        primaryMuscle: .chest,
        equipmentRequirement: "Macchinario",
        imageName: "chest_press_anim"
      ),
      ExerciseModel(
        name: "Alzate laterali ai cavi",
        description: "Tensione continua per i deltoidi.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Cavi",
        imageName: "lateral_raises_anim"
      ),
      ExerciseModel(
        name: "Curl con manubri su panca inclinata",
        description: "Isolamento per bicipiti in massimo allungamento.",
        primaryMuscle: .arms,
        equipmentRequirement: "Manubri e Panca",
        imageName: "bicep_curl_anim"
      ),
      ExerciseModel(
        name: "Curl a martello ai cavi",
        description: "Per bicipiti e brachioradiale.",
        primaryMuscle: .arms,
        equipmentRequirement: "Cavi",
        imageName: "bicep_curl_anim"
      ),
      ExerciseModel(
        name: "Leg Press (Pedana Alta)",
        description: "Versione della Leg Press per massimizzare il focus sui glutei/femorali. Tieni i piedi posizionati in alto.",
        primaryMuscle: .legs,
        equipmentRequirement: "Leg Press",
        imageName: "leg_press_anim"
      ),
      ExerciseModel(
        name: "Affondi con manubri (Split Squat)",
        description: "Esercizio per gambe e glutei (o Bulgarian Split Squat).",
        primaryMuscle: .legs,
        equipmentRequirement: "Manubri",
        imageName: "squat_anim"
      ),
      ExerciseModel(
        name: "Leg Curl disteso",
        description: "Isolamento femorali da posizione prona.",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "seated_leg_curl_anim"
      ),
      ExerciseModel(
        name: "Calf seduto",
        description: "Polpacci da seduto (stimolo sul soleo).",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "calf_press_anim"
      ),
      ExerciseModel(
        name: "Crunch inverso",
        description: "Esercizio dinamico per l'addome.",
        primaryMuscle: .core,
        equipmentRequirement: "Corpo libero",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Crunch a terra",
        description: "Flessioni del busto per stimolare il retto dell'addome.",
        primaryMuscle: .core,
        equipmentRequirement: "Tappetino",
        imageName: "bird_dog_anim"
      ),
    ]
  }

}
