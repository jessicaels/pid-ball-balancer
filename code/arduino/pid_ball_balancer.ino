#include <Servo.h>

Servo servo;
#define trig 2
#define echo 3

#define kp 19
#define ki 0.03
#define kd 15

double priError = 0;
double toError = 0;

#define SMOOTHING_WINDOW 5
int distBuffer[SMOOTHING_WINDOW];
int idx = 0;

void setup() {
  pinMode(trig, OUTPUT);
  pinMode(echo, INPUT);
  servo.attach(5);
  Serial.begin(9600);
  servo.write(50);

  // Inisialisasi buffer smoothing
  for (int i = 0; i < SMOOTHING_WINDOW; i++) {
    distBuffer[i] = 0;
  }
}

void loop() {
  int rawDist = distance();
  distBuffer[idx] = rawDist;
  idx = (idx + 1) % SMOOTHING_WINDOW;

  // Hitung rata-rata (moving average)
  int smoothDist = 0;
  for (int i = 0; i < SMOOTHING_WINDOW; i++) {
    smoothDist += distBuffer[i];
  }
  smoothDist /= SMOOTHING_WINDOW;

  PID_with_smooth(smoothDist);
  
  delay(50); // delay 50 ms supaya sampling rate ~20 Hz
}

long distance() {
  digitalWrite(trig, LOW);
  delayMicroseconds(4);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);

  long t = pulseIn(echo, HIGH);
  long cm = t / 29 / 2;
  return cm;
}

void PID_with_smooth(int dis) {
  int setP = 15;
  double error = setP - dis;

  double Pvalue = error * kp;
  double Ivalue = toError * ki;
  double Dvalue = (error - priError) * kd;

  double PIDvalue = Pvalue + Ivalue + Dvalue;
  priError = error;
  toError += error;

  int Fvalue = (int)PIDvalue;
  Fvalue = map(Fvalue, -135, 135, 135, 0);
  Fvalue = constrain(Fvalue, 0, 135);

  servo.write(Fvalue);

  // Kirim data smooth ke MATLAB
  Serial.print(dis);
  Serial.print(",");
  Serial.println(Fvalue);
}
