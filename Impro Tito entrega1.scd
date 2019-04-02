//s.boot

ServerOptions.devices;
(
s.options.outDevice = "Lexicon Lambda In/Out";
s.options.numOutputBusChannels = 2;
s.reboot;
)

(
Server.default.record; // para grabar

Server.default.stopRecording //para parar grabación
)

//1 WATER

//«running water (simple)» by LFSaw https://sccode.org/1-576
// Gui low freq 276.92 aprox para iniciar al final bajar frec
// inicia low freq 800, cambia a 400, 600, 800
// LFNoise puede bajar de 1700 hasta 400-600 y regresa

(
Ndef(\simpleRunningWater).fadeTime = 4;


Ndef(\simpleRunningWater, {
	var mod, freq, ampMod, src;

	mod = {LFNoise0.ar(1700)}!2;

	freq = mod.linexp(-1, 1, \lowFreq.kr(200, 2), 800).lag(0.01); //  * Line.kr(1, 0.01, 40);
	ampMod = 0.2 + mod.linlin(-1, 1, 0.5, 0).lag(0.1);

	ampMod = ampMod * AmpComp.ar(freq);

	src = LPF.ar(SinOsc.ar(
		freq,
		0.2,
		ampMod
	), 2000);

	//src * LFPulse.ar(10);
	src

})
)

Ndef(\simpleRunningWater).set(\lowFreq, 1000);
Ndef(\simpleRunningWater).xset(\lowFreq, 1000);
Ndef(\simpleRunningWater).gui

//II CHICAGO PAD TITO

// parametros modificar del pad en vivo: cutoff, degree (tono), root (cambia de nota -2), legato (aguas), cutoff4500 y dur acaso

(
SynthDef(\ChicagoPad2vTito, { |out = 0, freq = 440, freq2=660, freq3=528, cutoff = 500, amp = 0.2, gate=1|

    var snd;
    var delay = 0.045+0.05;

    freq = freq + SinOsc.kr(freq*1/2, 0, freq/2, 0);

    snd = Saw.ar([freq, freq+1, freq-1, freq2, freq3] * [0.99,1])*0.1;

    snd = snd + VarSaw.ar(0.99*[freq, freq+1, freq-1, freq2, freq3, freq2+1, freq3+1],0, LFTri.kr(7.13).range(0.00,0.1))*0.1;


    snd = Mix(snd);
    snd = FreeVerb.ar(snd, 0.51,10,0.1)*2;
    snd = snd *8;
    snd = RLPF.ar(snd, SinOsc.kr([0.1,4.2], 0, [1700,480], [4000,700,5000])/[20.51,20], SinOsc.ar(0.1,1.5*pi)+1.05)/3;
    snd = Mix(snd);

    snd = MoogFF.ar(snd, SinOsc.kr(0.08, 0.5, cutoff/10, cutoff), 3, 0);

    snd = snd * EnvGen.ar(Env.dadsr(delay,0.4, 0.01,0.8,0.4), gate, doneAction:2);
    //snd = snd * EnvGen.ar(Env.adsr(0.4, 0.01,0.8,0.4), gate, doneAction:2);

    snd = [snd , AllpassC.ar(snd, delay, 0.05+SinOsc.ar(0.11).range(0,0.045), 0.3)];
    snd = snd * amp;
    Out.ar(out, snd);

}).add;
)

(
Pdef(\plop2, Pbind(
	\instrument, \ChicagoPad2vTito,
	\degree, Pseq([0,],inf),
	\root, -4,
	\freq2, Pkey(\freq)*(3/2) / 2,
	\freq3, Pkey(\freq)*(5/6) / 2,
	\legato, 1,
	//\cutoff, 4500,
	\dur, 15,
	\amp, 0.20
//)).play;
)).stop;
);

// III DRONE

//https://github.com/supercollider/supercollider/wiki/Recording-in-SuperCollider-(WIP), ejemplo de drone tomado de ahí  y modificado por mi
//intensidad: Gendy1.ar higher: (1,1,1,1) lower: (2,2,2,2)
(
SynthDef(\droneTito, {
            |out = 0, freq = 440, amp = 0.1, gate = 1, attack = 0.3, release = 0.3|
            var snd, ffreq, res;
            snd = { Gendy1.ar(1.5, 1.5, 1.5, 1.5, freq * 0.99, freq * 1.01) }!5;
	        //snd = { Gendy1.ar(1, 1, 1, 1, freq * 0.99, freq * 1.01) }!5;
            snd = Splay.ar(snd);
            ffreq = LFNoise2.kr(1).exprange(100, 3000);
            res = LFNoise2.kr(3).range(1.0, 0.3);
            snd = RLPF.ar(snd, ffreq, res);
            snd = snd * amp * Env.asr(attack, 1, release).ar(2, gate);
            Out.ar(out, snd);
        }).add;
)
x= Synth(\droneTito);

x.free;

// IV Tdef //sound example from browser// modificar rrand de 200 a 400, 600, 800 etc. //revisarlo se puede hacer algo mejor

(
SynthDef(\pdef_grainlet,
    { arg out=0, freq=440, sustain=0.1;
        var env;
        env = EnvGen.kr(Env.perc(0.05, sustain, 0.1), doneAction:2);
        Out.ar(out, LFTri.ar(freq, 0, env))
    }).add;
)
Tdef(\x).play;

(
Tdef(\x, {
    loop({
        s.sendMsg("/s_new", "pdef_grainlet", -1,0,0, \freq, rrand(200, 400));
        3.wait;
    })
})
)

Tdef(\x).stop;

//V Pad Voices   http://www.kimri.org/blog/?p=64
(
SynthDef(\voice,{arg out=0,n=0,p=0,d=10,r=10;
var sig=Array.fill(3,{|i| VarSaw.ar(n.midicps*(i+1.0001),mul:0.05/(i+1))}).sum;
var sig2=Ringz.ar(WhiteNoise.ar(0.0003),TRand.ar(n.midicps,(n+1).midicps,Impulse.ar(10)));
var env=EnvGen.kr(Env.linen(d,1,r),gate:1,doneAction:2);
Out.ar(out,Pan2.ar((sig+sig2)*env*(0.8+SinOsc.kr(0.1,0,0.2)),p));
}).add;
)

Ndef(\rev,{
Out.ar(0,Limiter.ar(FreeVerb.ar(LPF.ar(In.ar([0,1]),10000),mix:0.33),0.7));
};
);

Tdef(\voices,{
inf.do{
10.do{
if ((0.8).coin,{
Synth(\voice,[\n:[24,28,29,48,36,40,41,52,53,60,64,65].choose,\p:{rrand(-0.5,0.5)},\d:{rrand(5,13)},\r:{rrand(8,14)}]);
});
rrand(0.1,1).wait;
};
18.wait;
};
});

Tdef(\voices).play;
Tdef(\voices).stop; //este stop hace fade out, es lo primero que sale y de aquí nos regresamos muteando sección por sección hasta terminar


s.quit