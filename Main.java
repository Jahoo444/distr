import java.util.*;
import java.io.*;

public class Main
{
	public static void main( String[] args )
	{
		ArrayList< Node > nodes;
		
		try
		{
			BufferedReader in = new BufferedReader( new FileReader( new File( "data.txt" ) ) );
			int numNodes = Integer.parseInt( in.readLine() );
			
			nodes = new ArrayList< Node >( numNodes );
			
			for( int i = 0; i < numNodes; i++ )
				nodes.add( i, new Node( i ) );
			
			System.out.println( numNodes );
			
			for( int i = 0; i < numNodes; i++ )
			{
				String[] items = in.readLine().split( " " );
				ArrayList< Node > neighbours = new ArrayList< Node >( items.length );
				
				for( int j = 0; j < items.length; j++ )
				{
					int node = Integer.parseInt( items[ j ] );
					neighbours.add( j, nodes.get( node ) );
				}
				
				nodes.get( i ).setNeighbours( neighbours );
			}
			
			for( Node node : nodes )
				node.start();
		}
		catch( Exception ex )
		{
			
		}
	}
}