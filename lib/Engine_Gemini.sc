Engine_Gemini : CroneEngine {
	// Define a getter for the synth variable
	var <synth;
    var <buffer;
    var <phaseL;
    var <phaseR;
    var <level;
    var <seek_task;

	// Define a class method when an object is created
	*new { arg context, doneCallback;
		// Return the object from the superclass (CroneEngine) .new method
		^super.new(context, doneCallback);
	}


    // disk read
	readBuf { arg path;
		if(buffer.notNil, {
			if (File.exists(path), {
				var newbuf = Buffer.readChannel(context.server, path, 0, -1, [0], {
					synth.set(\buf, newbuf);
					buffer.free;
					buffer = newbuf;
				});
			});
		});
	}



	// Rather than defining a SynthDef, use a shorthand to allocate a function and send it to the engine to play
	// Defined as an empty method in CroneEngine
	// https://github.com/monome/norns/blob/master/sc/core/CroneEngine.sc#L31
	alloc
    {
      buffer = Buffer.alloc(
				context.server,
				context.server.sampleRate * 1,
			);
    
            SynthDef(\gemini, {
                arg out, phase_outL, phase_outR, buf,
                durationL=10, durationR=10,
                jitterL=0, jitterR=0.0,
                sizeL=0.1, sizeR=0.1,
                trigRateL=5.0, trigRateR=5.0,
                pitchL=1, pitchR=1,
                gate=0, t_reset_pos=0;

                var trigRate, trigger;
                var playRate, duration, grainSize, jitter;
                var phasor;
                var buf_dur, buf_pos, pos_sig, jitter_sig, sig;
                var env;

                buf_dur = BufDur.kr(buf);

                duration = [durationL, durationR];
                trigRate = [trigRateL, trigRateR];
                playRate = [pitchL, pitchR];
                grainSize = [sizeL, sizeR];
                jitter = [jitterL, jitterR];

                trigger = Impulse.kr(trigRate);

                jitter_sig = TRand.kr(trig: trigger,
                    lo: buf_dur.reciprocal.neg * jitter,
                    hi: buf_dur.reciprocal * jitter);

                buf_pos = Phasor.kr(
                    trig: t_reset_pos,
                    rate: (1.0/ControlRate.ir) / duration,
                    resetPos: 0.0);

                pos_sig = Wrap.kr(buf_pos);

                sig = GrainBuf.ar(1, trigger, grainSize, buf, playRate, pos_sig + jitter_sig);
                env = EnvGen.kr(Env.asr(1, 1, 1), gate: gate);

                Out.ar(out, sig * env);
                Out.kr(phase_outL, pos_sig[0]);
                Out.kr(phase_outR, pos_sig[1]);
            }).add;

        context.server.sync;
        
        phaseL = Bus.control(context.server);
        phaseR = Bus.control(context.server);

        synth = Synth.new(\gemini, [
            \out, context.out_b.index,
            \phase_outL, phaseL,
            \phase_outR, phaseR,
            \buf, buffer
        ], context.xg);

        context.server.sync;

        this.addCommand("read", "s", { arg msg;
			this.readBuf(msg[1]);
		});

    this.addCommand("seek", "f", { arg msg;
			var pos;
			var seek_rate = 1 / 750;

			seek_task.stop;

			if (false, { // disable seeking until fully implemented
				var step;
				var target_pos;

				// TODO: async get
				pos = phaseL.getSynchronous();
				synth.set(\freeze, 1);

				target_pos = msg[1];
				step = (target_pos - pos) * seek_rate;

				seek_task = Routine {
					while({ abs(target_pos - pos) > abs(step) }, {
						pos = pos + step;
						synth.set(\pos, pos);
						seek_rate.wait;
					});

					synth.set(\pos, target_pos);
					synth.set(\freeze, 0);
					synth.set(\t_reset_pos, 1);
				};

				seek_task.play();
			}, {
				pos = msg[1];

				synth.set(\pos, pos);
				synth.set(\t_reset_pos, 1);
			});
		});


        this.addCommand("gate", "i", { arg msg;
			synth.set(\gate, msg[1]);
		});


        this.addCommand("durationL", "f", { arg msg;
			synth.set(\durationL, msg[1]);
		});

        this.addCommand("durationR", "f", { arg msg;
			synth.set(\durationR, msg[1]);
		});


        this.addCommand("jitterL", "f", { arg msg;
			synth.set(\jitterL, msg[1]);
		});

        this.addCommand("jitterR", "f", { arg msg;
			synth.set(\jitterR, msg[1]);
		});


        this.addCommand("sizeL", "f", { arg msg;
			synth.set(\sizeL, msg[1]);
		});

        this.addCommand("sizeR", "f", { arg msg;
			synth.set(\sizeR, msg[1]);
		});


        this.addCommand("trigRateL", "f", { arg msg;
			synth.set(\trigRateL, msg[1]);
		});

        this.addCommand("trigRateR", "f", { arg msg;
			synth.set(\trigRateR, msg[1]);
		});


        this.addCommand("pitchL", "f", { arg msg;
			synth.set(\pitchL, msg[1]);
		});

        this.addCommand("pitchR", "f", { arg msg;
			synth.set(\pitchR, msg[1]);
		});


        this.addPoll(("phaseL").asSymbol, {
				var val = phaseL.getSynchronous;
				val
		});

        this.addPoll(("phaseR").asSymbol, {
				var val = phaseR.getSynchronous;
				val
		});
	}

	// define a function that is called when the synth is shut down
	free {
		synth.free;
        buffer.free;
        phaseL.free;
        phaseR.free;
	}
}