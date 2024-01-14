#include <iostream>
#include <fstream>
#include <hil.h>
#include <quanser_runtime.h>
#include <quanser_types.h>
#include <quanser_arguments.h>
#include <quanser_errors.h>
#include "quanser_signal.h"
#include "quanser_messages.h"
#include "quanser_thread.h"
#include "qubeControl.h"
#define _USE_MATH_DEFINES
#include <math.h>
#include <string>
#include "angleCalculation.h"
#include "timing.h"
#include "signalProcessing.h"

#define ALPHALIMIT (M_PI/18)
#define THETALIMIT (M_PI/3) //Stop device if theta is more than +-60°
#define INTEGRALLIMIT 0.5
#define VOLTAGELIMIT 7.5 //Max voltage +-15V in manual.  Doesn't usually go above 2 on scopes

//Task setup
const t_uint32 samples = -1; // Read Continuously
const t_double frequency = 150; //Standard 500
const t_uint32 samples_in_buffer = (t_uint32)(0.1 * frequency); //Frequency defined in Qube control
const t_double period = 1.0 / frequency;
t_int samples_read = 0;
t_task task;

//Control Variables
//double K[1][5] = {{ -1.0000, -1.6618, 36.7459, -1.6227, 3.2421 }}; //Test Q = diag([1, 0, 1, 1, 1]); R = 1; - Works for AlphaCam
//double K[1][5] = {{ -1.4142, -2.3273, 47.8968, -2.1569, 4.3497 }}; //Test Q = diag([1, 0, 1, 1, 1]); R = 0.5;
double K[1][5] = {{ -0.7071, -1.1952, 29.0980, -1.2521, 2.4797 }}; //Test Q = diag([1, 0, 1, 1, 1]); R = 2;

t_int32 armEncoderCount;
t_int32 pendulumEncoderCount;
double thetaQube;
double alphaQube;
double thetaQubeLast;
double alphaQubeLast;
double thetaDotQube;
double alphaDotQube;
double thetaTarget = 0.0;
double thetaIntegral = 0.0;
double Kx = 0.0;
double KxCam = 0.0;
t_double voltage[] = { 0.0 };

//App logic
bool camControl = false;
double * camControlActiveAlpha = &alphaFiltered;
double * camControlActiveAlphaDot = &alphaDotKalman;

void signalHandler(int signal)
{
    stop = 1;
}

void setupSignalHandler(qsigaction_t action) {
    action.sa_handler = signalHandler;
    action.sa_flags = 0;
    qsigemptyset(&action.sa_mask);

    qsigaction(SIGINT, &action, NULL);
}

t_error setupBoard(t_card* board) {
    t_error openResult = hil_open("qube_servo2_usb", "0", board);
    //Reset encoders
    if (hil_set_encoder_counts(*board, encoderChannels, encoderChannelCount, encoderChannelStart) != 0) {
        std::cout << "Couldn't reset encoders" << std::endl;
    }
    //Motor is off at start
    if (hil_write_analog(*board, analogChannels, analogChannelCount, voltage) != 0) {
        std::cout << "Couldn't zero voltage" << std::endl;
    }
    //Turn on motor    
    if (hil_write_digital(*board, digitalChannels, digitalChannelCount, &enable) != 0) {
        std::cout << "Couldn't enable motor" << std::endl;
    }

    return openResult;
}

t_error taskPreparation(t_card* board) {
    //Increase our thread priority so we get better sample time performance
    qsched_param_t scheduling_parameters;
    scheduling_parameters.sched_priority = qsched_get_priority_max(QSCHED_FIFO);
    qthread_setschedparam(qthread_self(), QSCHED_FIFO, &scheduling_parameters);

    //Create a task to read the encoder. The task will be used to time the control loop
    t_error taskResult = hil_task_create_encoder_reader(*board, samples_in_buffer, encoderChannels, encoderChannelCount, &task);

    return taskResult;
}

void getEncoderValuesSimple(t_card* board) {
    hil_read_encoder(*board, encoderChannels, encoderChannelCount, &encoderCounts[0]);
    armEncoderCount = encoderCounts[0];
    pendulumEncoderCount = encoderCounts[1];
}

void getEncoderValuesTask() {
    samples_read = hil_task_read_encoder(task, 1, &encoderCounts[0]);
    armEncoderCount = encoderCounts[0];
    pendulumEncoderCount = encoderCounts[1];
}

void calculateRadians() {
    thetaQube = (double) armEncoderCount * -2 * M_PI / 512 / 4; //Calculation from Simulink 
    alphaQube = std::fmod((double) pendulumEncoderCount * 2 * M_PI / 512 / 4, 2 * M_PI) - M_PI; //Use angle with mod 2pi and pi bias as per Simulink
}

void updateLastValues() {
    //Update last count
    thetaQubeLast = thetaQube;
    alphaQubeLast = alphaQube;
}

void differentiatePosition() {
    thetaDotQube = (double) (thetaQube - thetaQubeLast) / period;
    alphaDotQube = (double) (alphaQube - alphaQubeLast) / period;
}

void integrateError() {
    if (!camControl) {
        if (abs(alphaQube) < ALPHALIMIT) {
            if (abs(alphaQubeLast >= ALPHALIMIT)) {
                //Reset integral to avoid windup
                thetaIntegral = 0.0;
            }
            //Add to integral if not too high to avoid windup
            if (thetaIntegral < INTEGRALLIMIT) {
                thetaIntegral += (thetaQube - thetaTarget) * period;
            }
        }
    }
    else {
        if (abs(alphaCam) < ALPHALIMIT) {
            if (abs(alphaCamLast >= ALPHALIMIT)) {
                //Reset integral to avoid windup
                thetaIntegral = 0.0;
            }
            //Add to integral if not too high to avoid windup
            if (thetaIntegral < INTEGRALLIMIT) {
                thetaIntegral += (thetaQube - thetaTarget) * period;
            }
        }
    }    
}

t_error updateVoltage(t_card* board) {
    //Update voltage
    KxCam = K[0][0] * thetaIntegral + K[0][1] * thetaQube + K[0][2] * *camControlActiveAlpha + K[0][3] * thetaDotQube + K[0][4] * *camControlActiveAlphaDot; //-Kx with inversion for +ve CCW - LOW PASS Camera
    Kx = K[0][0] * thetaIntegral + K[0][1] * thetaQube + K[0][2] * alphaQube + K[0][3] * thetaDotQube + K[0][4] * alphaDotQube; //-Kx with inversion for +ve CCW
    
    if (abs(thetaQube) > THETALIMIT) {
        //Theta safety
        voltage[0] = 0.0;
    }
    else {
        if (camControl) {
            if (abs(alphaCam) < ALPHALIMIT) {
                if (abs(KxCam) < VOLTAGELIMIT) {
                    voltage[0] = KxCam;
                }
                else {
                    voltage[0] = KxCam / abs(KxCam) * VOLTAGELIMIT; //Set to voltage limit with correct sign
                }
            }
        }
        else {
            if (abs(alphaQube) < ALPHALIMIT) {
                if (abs(Kx) < VOLTAGELIMIT) {
                    voltage[0] = Kx;
                }
                else {
                    voltage[0] = Kx / abs(Kx) * VOLTAGELIMIT; //Set to voltage limit with correct sign
                }
            }
        }
    }    
    
    //Write Voltage to device
    t_error voltageResult = hil_write_analog(*board, analogChannels, analogChannelCount, voltage);

    return voltageResult;
}

void printFinalState() {
    std::cout << "Final state" << std::endl;
    for (t_int32 channel = 0; channel < encoderChannelCount; channel++)
        printf("ENC #%d: %7d   ", encoderChannels[channel], encoderCounts[channel]);
    printf("\n");
    for (t_int32 channel = 0; channel < analogChannelCount; channel++)
        printf("VOLTAGE #%d: %7f   ", analogChannels[channel], voltage[channel]);
    printf("\n");
    std::cout << "Kx: " << std::to_string(Kx) << std::endl;
    std::cout << "Z: " << std::to_string(thetaIntegral) << std::endl;
    std::cout << "Theta: " << std::to_string(thetaQube) << std::endl;
    std::cout << "Alpha: " << std::to_string(alphaQube) << std::endl;
    std::cout << "ThetaDot: " << std::to_string(thetaDotQube) << std::endl;
    std::cout << "AlphaDot: " << std::to_string(alphaDotQube) << std::endl;
}

t_error shutdownBoard(t_card* board) {
    enable = 0;
    voltage[0] = 0.0;
    hil_write_analog(*board, analogChannels, analogChannelCount, voltage); //Set voltage to 0
    hil_write_digital(*board, digitalChannels, digitalChannelCount, &enable); //Turn off motor
    t_error shutdownResult = hil_close(*board);
    
    return shutdownResult;
}

void updateThetaTarget(float target) {
    thetaTarget = target/180*M_PI;
}