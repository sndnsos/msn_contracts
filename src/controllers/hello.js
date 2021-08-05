const {koaRouter,ROOTDIR } =require("../global.js");//all the global data and initialization
const {HelloWorld} =require("../manager/HelloWorld.js");


koaRouter.get('/hello/world',async (ctx,next) =>{
    ctx.body={msg:HelloWorld.echo()};
    await next();
});