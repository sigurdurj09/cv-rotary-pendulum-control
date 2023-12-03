#ifndef QUBE_CONTROL
#define QUBE_CONTROL

#include <hil.h>
#include <quanser_runtime.h>
#include <quanser_types.h>
#include <quanser_arguments.h>
#include <quanser_errors.h>
#include "quanser_signal.h"
#include "quanser_messages.h"
#include "quanser_thread.h"
#include "qubeControl.h"

extern int stop;

//Channel setup
extern const t_uint32 analogChannels[];
extern const t_uint32 encoderChannels[];
extern const t_uint32 digitalChannels[];
extern t_int32 encoderCounts[];
extern const t_int32 encoderChannelStart[];
extern const t_int32 analogChannelCount;
extern const t_int32 encoderChannelCount;
extern const t_int32 digitalChannelCount;

//Task setup
extern const t_uint32 samples;
extern const t_double frequency;
extern const t_uint32 samples_in_buffer;
extern const t_double period;
extern t_int samples_read;
extern t_task task;

//Control Variables
extern double K[1][5];
extern t_int32 armEncoderCount;
extern t_int32 pendulumEncoderCount;
extern double thetaQube;
extern double alphaQube;
extern double thetaQubeLast;
extern double alphaQubeLast;
extern double thetaDotQube;
extern double alphaDotQube;
extern double thetaTarget;
extern double thetaIntegral;
extern double Kx;
extern double KxCam;
extern t_double voltage[];
extern t_boolean enable;

//App logic
extern bool camControl;

void setupSignalHandler(qsigaction_t action);
t_error setupBoard(t_card* board);
t_error taskPreparation(t_card* board);
void getEncoderValuesSimple(t_card* board);
void getEncoderValuesTask();
void calculateRadians();
void updateLastValues();
void differentiatePosition();
void integrateError();
t_error updateVoltage(t_card* board);
void printFinalState();
t_error shutdownBoard(t_card* board);
void updateThetaTarget(float target);

#endif