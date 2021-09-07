exports.handler = function(event, context) {
    console.log('Hello, Cloudwatch!');
    context.succeed('Hello, World!');
   };